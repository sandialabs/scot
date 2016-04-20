package Scot::App::Migrate2;

use lib '../../../lib';

=head1 Name

Scot::App::Migrate

=head1 Description

This controller will migrate a SCOT < 3.4 database
to a SCOT 3.5 database

=cut

use Scot::Env;
use Scot::Util::EntityExtractor;
use MongoDB;
use Data::Dumper;
use Try::Tiny;
use HTML::Entities;
use Time::HiRes qw(gettimeofday tv_interval);
use Safe::Isa;
use Storable;
use HTML::TreeBuilder;
use v5.18;
use strict;
use warnings;


use Moose;

has env => (
    is          => 'rw',
    isa         => 'Scot::Env',
    required    => 1,
    builder     => '_get_env',
);

sub _get_env {
    return Scot::Env->instance;
}

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Util::EntityExtractor',
    required    => 1,
    lazy        => 1,
    builder     => '_get_ee',
);

sub _get_ee {
    my $self    = shift;
    my $log     = $self->env->log;
    return Scot::Util::EntityExtractor->new({log=>$log});
}

has legacy_client   => (
    is          => 'rw',
    isa         => 'MongoDB::MongoClient',
    required    => 1,
    lazy        => 1,
    builder     => '_get_connection',
);

sub _get_connection {
    my $self    = shift;
    return MongoDB->connect();
}

has legacydb    => (
    is          => 'rw',
    isa         => 'MongoDB::Database',
    required    => 1,
    lazy        => 1,
    builder     => '_get_legacy_db',
);

has legacy_db_name  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'scotng-prod',
);

sub _get_legacy_db {
    my $self    = shift;
    # return $self->legacy_client->get_database('scotng-prod');
    return MongoDB->connect->db('scotng-prod');
}

has default_read    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub { [ 'wg-scot-ir' ] },
);
has default_modify    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub { [ 'wg-scot-ir' ] },
);

has client  => (
    is          => 'rw',
    isa         => 'MongoDB::MongoClient',
    required    => 1,
    lazy        => 1,
    builder     => '_get_connection',
);

has db    => (
    is          => 'rw',
    isa         => 'MongoDB::Database',
    required    => 1,
    lazy        => 1,
    builder     => '_get_db',
);

has db_name  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'scot-prod',
);

sub _get_db {
    my $self    = shift;
    # return $self->legacy_client->get_database('scotng-prod');
    return MongoDB->connect->db($self->db_name);
}

sub get_min_id {
    my $self    = shift;
    my $mtype   = shift;
    my $idrange = shift;
    my $col     = $self->db->get_collection($mtype);
    my $cursor  = $col->find({
        id => { '$gte' => $idrange->[0], '$lte' => $idrange->[1] }
    });
    $cursor->sort({ id => 1});
    my $doc = $cursor->next;
    unless ($doc) {
        return $idrange->[1];
    }
    return $doc->{id};
}


sub migrate {
    my $self    = shift;
    my $mtype   = shift;
    my $mname   = ucfirst($mtype);
    my $opts    = shift;

    my $env     = $self->env;
    my $log     = $env->log;

    my $num_proc    = $opts->{num_proc} // 0;
    my $forkmgr     = Parallel::ForkManager->new($num_proc);

    my @idranges    = $self->get_idranges($opts, $mtype);

    my $procindex   = 0;
    my $idfield     = $self->lookup_idfield($mtype);

    PROCGROUP:
    foreach my $id_range ( @idranges ) {
        $forkmgr->start($procindex++) and next PROCGROUP;

        $self->legacy_client->reconnect();
        $self->client->reconnect();

        my $min_migrated_id = $self->get_min_id($mtype, $id_range);

        my $colname     = $self->lookup_legacy_colname($mtype);
        my $legcol      = $self->legacydb->get_collection($colname);
        my $legcursor   = $legcol->find({
            $idfield    => {
                '$gte'  => $id_range->[0],
                '$lte'  => $min_migrated_id,
            }
        });
        $legcursor->immortal(1);
        $legcursor->sort({$idfield => -1});
        my $remaining_docs  = $legcursor->count();
        my $migrated_docs   = 0;
        my $total_docs      = $remaining_docs;
        my $total_time      = 0;

        ITEM:
        while ( my $item = $self->get_next_item($legcursor) ) {

            if ( $item  eq "skip" ) {
                $migrated_docs++;
                next;
            }

            my $timer   = $env->get_timer("[$mname ".$item->{$idfield}.
                            "] Migration");
            
            my $pct = $self->get_pct($remaining_docs, $total_docs);

            my $alert_count; # only for alertgroup special case
            if ( $mtype eq "alertgroup" ) {
                $alert_count = scalar(@{$item->{alert_ids}}) // 0;
            }

            if ($opts->{verbose} ) {
                my $postspace   = 4 - $procindex;
                print " "x$procindex .$procindex.
                    " "x$postspace.": {". $$ ."}[ $mname ". $item->{$idfield}.
                    "] ";
                if ( $mtype eq "alertgroup" ) {
                    my $acfmt   = sprintf("%15s", $alert_count);
                    print "$acfmt alerts to process \r";
                }
            }
            
            unless ( $self->transform($mtype, $item) ) {
                $log->error("Error: $mtype Transform failed ",
                            { filter => \&Dumper, value=> $item });
            }
            
            my $elapsed = &$timer;
            $total_time += $elapsed;
            $remaining_docs--;
            $migrated_docs++;
            my ($rate, $eta) = $self->calc_rate_eta($elapsed, $remaining_docs);
            # my ($rate, $eta) = $self->calc_rate_eta($total_time, $remaining_docs);

            my $ratestr = sprintf("%16s", sprintf("%5.3f docs/sec", $rate));
            my $etastr  = sprintf("%16s", sprintf("%5.3f hours", $eta));
            my $elapstr = sprintf("%5.2f", $elapsed);
            if ($opts->{verbose} ) {
                my $postspace   = 4 - $procindex;
                print " "x$procindex .$procindex.
                    " "x$postspace.": {". $$ ."}[ $mname ". $item->{id}.
                    "] $elapstr secs - ";
                if ( $mtype eq "alertgroup" ) {
                    my $acfmt   = sprintf("%5s", $alert_count);
                    print "$acfmt alerts - ";
                }
                print " $ratestr $etastr ".  $self->commify($remaining_docs). " remain\n";
            }
        }

        $forkmgr->finish;
    }
    $forkmgr->wait_all_children;
}

sub get_idranges {
    my $self    = shift;
    my $opts    = shift;
    my $mtype   = shift;
    my $idfield = $self->lookup_idfield($mtype);

    my @ids    = ();

    if ( -e $mtype."_idranges" ) {
        @ids    = retrieve($mtype."_idranges");
        return wantarray ? @ids : \@ids;
    }

    if ( $opts->{idranges} ) {
        return wantarray ? @{$opts->{idranges}} : $opts->{idranges};
    }

    my $numprocs    = $opts->{num_proc} // 1;
    my $colname = $self->lookup_legacy_colname($mtype);
    my $legcol  = $self->legacydb->get_collection($colname);
    my $cursor  = $legcol->find();
    $cursor->immortal(1);
    my $total_docs      = $cursor->count;

    if ( $numprocs == 1 or $mtype eq "guide" or $mtype eq "handler" ) {
        @ids    = (
            [ 1, $total_docs + 1 ],
        );
        return wantarray ? @ids : \@ids;
    }

    # docs per processor
    my $dpp   = int( $total_docs / $numprocs ) + 1;

    if ( $opts->{verbose} ) {
        say "Scanning ". $self->commify($total_docs). " $colname documents ".
            "for id ranges";
    }

    my $count   = 0;
    my @range   = ();
    while ( my $item = $cursor->next ) {
        if ( $count % 100 == 0  and $opts->{verbose}) {
            printf "%20s\r", $self->commify(scalar(@range));
        }
        $count++;
        push @range, $item->{$idfield};
        if ( scalar(@range) >= $dpp ) {
            if ( $opts->{verbose} ) {
                say "";
                say "... reached   ".$self->commify($dpp)." limit";
                say "... contains  ".$self->commify(scalar(@range))." ids";
                say "... start_id = " . $range[0];
                say "... end_id   = " . $range[-1];
                say "";
            }
            push @ids, [ $range[0], $range[-1] ];
            @range = ();
        }
    }

    $self->env->log->debug("$mtype idranges ",{filter=>\&Dumper, value=>\@ids});

    store @ids, $mtype."_idranges";

    return wantarray ? @ids : \@ids;

}

sub transform {
    my $self    = shift;
    my $mtype   = shift;
    my $item    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $newdb   = $self->db;
    my $newcol  = $newdb->get_collection($mtype);
    my $method  = "xform_".$mtype;
    my $idfield = delete $item->{idfield} // $self->lookup_idfield($mtype);
    my $id      = delete $item->{$idfield};
    $item->{id} = $id // '';

    my $newitem = $newcol->find_one({id => $id});

    if ( $newitem ) {
        $log->debug("[$mtype $id] already migrated...");
        return 1;
    }

    if ( $item->{updated} ) {
        $item->{updated}    = int($item->{updated});
    }

    if ( $item->{readgroups} ) {
        $item->{groups} = {
            read    => delete $item->{readgroups}   // $self->default_read,
            modify  => delete $item->{modifygroups} // $self->default_modify,
        };
    }

    $log->trace("[$mtype $id] removing unneeded fields");
    foreach my $attribute ( @{ $self->get_unneeded_fields($mtype) }) {
        delete $item->{$attribute};
    }

    return $self->$method($newcol, $item);

}

sub xform_event {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $verbose = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->debug("[Event $id] transformation");

    my @links;
    my @alinks = map {
        { pair  => [ { type => "alert", id => $_ },
                     { type => "event", id => $id }, ],
          when  => $href->{created} // $href->{updated} }
    } @{ delete $href->{alerts} // [] };
    my @ilinks = map {
        { pair  => [ { type => "incident", id => $_ },
                     { type => "event", id => $id }, ],
          when  => $href->{created} // $href->{updated} }
    } @{ delete $href->{incidents} // [] };
    push @links, @alinks, @ilinks;

    my @history = map {
        { event => $id, history => $_ }
    } @{ delete $href->{history} //[] };
    my @tags    = map {
        { events => $id, tag => { value => $_ } }   
    } @{ delete $href->{tags} //[] };
    my @sources = map {
        { events => $id, source => { value => $_, } }
    } @{ delete $href->{sources} //[] };

    $href->{views}  = delete $href->{view_count};

    $col->insert_one($href);

    push @links, $self->create_history(@history);
    push @links, $self->create_sources(@sources);
    push @links, $self->create_tags(@tags);
    $self->create_links(@links);

    return 1;

}

sub xform_incident {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $verbose = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->debug("[Incident $id] transformation ");

    my @links = map { 
        { pair  => [ {type  => "event", id    => $_, }, 
                     {type  => "incident", id => $id }, ],
          when  => $href->{created}//$href->{updated} } 
    } @{ delete $href->{events} // [] };

    unless ( defined $href->{owner} ) {
        $href->{owner} = "unknown";
    }
    my @history = map {
        { event => $id, history => $_ }
    } @{ delete $href->{history} //[] };
    my @tags    = map {
        { events => $id, tag => { value => $_ } }   
    } @{ delete $href->{tags} //[] };
    my @sources = map {
        { events => $id, source => { value => $_, } }
    } @{ delete $href->{sources} //[] };

    $col->insert_one($href);

    push @links, $self->create_history(@history);
    push @links, $self->create_sources(@sources);
    push @links, $self->create_tags(@tags);
    $self->create_links(@links);

    return 1;
}
sub xform_entry {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $verbose = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->debug("[Entry $id] transformation ");

    if ( length($href->{body}) > 2000000 ) {
        $log->warn("[Entry $id] is HUGE! Saving for later splitting");
        $self->handle_huge_entry($id);
        return undef;
    }

    if ( ref($href->{body}) eq "MongoDB::BSON::Binary" ) {
        $href->{body} = '<html>'.$href->{plaintext}.'</html>';
    }

    my $entities;

    ( $href->{body_flair},
      $href->{body_plain},
      $entities )   = $self->flair_entry_data($href);

    $href->{parent}     = 0 unless ($href->{parent});
    $href->{owner}      = 'unknown' unless ($href->{owner});
    # this must be after the flairing bc flairing looks for target_type/id
    $href->{target}     = {
        type        => delete $href->{target_type},
        id          => delete $href->{target_id},
    };
    my @history = map {
        { event => $id, history => $_ }
    } @{ delete $href->{history} //[] };
    my @links;
    push @links, $self->create_history(@history);
    push @links, $self->create_entities($entities);
    $self->create_links(@links);
    return 1;
}

sub xform_alertgroup {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $verbose = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->debug("[Alertgroup $id] transformation ");

    my @links = map { 
        { pair  => [ {type  => "event", id    => $_, }, 
                     {type  => "alertgroup", id => $id }, ],
          when  => $href->{created}//$href->{updated} } 
    } @{ delete $href->{events} // [] };

    my @history = map {
        { alertgroup => $id, history => $_ }
    } @{ delete $href->{history} //[] };
    my @tags    = map {
        { alertgroup => $id, tag => { value => $_ } }   
    } @{ delete $href->{tags} //[] };
    my @sources = map {
        { alertgroup => $id, source => { value => $_, } }
    } @{ delete $href->{sources} //[] };

    $href->{body}        = delete $href->{body_html};

    my $newalertcol     = $self->db->get_collection('alert');
    my $leg_alert_col   = $self->legacydb->get_collection('alerts');
    my $leg_alert_cursor= $leg_alert_col->find({alertgroup => $id});
    $leg_alert_cursor->immortal(1);
    my $alert_count     = $leg_alert_cursor->count();
    my $entities;
    my @alert_promotions    = ();
    my %status;
    my @allentities = ();

    ALERT:
    while ( my $alert = $leg_alert_cursor->next ) {
        my $alertid     = $alert->{alert_id};
        $alert->{id}    = delete $alert->{alert_id};
        die "No AlertID! ".Dumper($alert) unless (defined $alertid);
        $status{$alert->{status}}++;
        $log->trace("[alert $alertid] removing unneeded fields");
        foreach my $attribute ( @{ $self->get_unneeded_fields('alert') }) {
            delete $alert->{$attribute};
        }
        if ( $alert->{updated} ) {
            $alert->{updated}    = int($alert->{updated});
        }

        if ( $alert->{readgroups} ) {
            $alert->{groups} = {
                read    => delete $alert->{readgroups} // $self->default_read,
                modify  => delete $alert->{modifygroups} // $self->default_modify,
            };
        }
        my @alerthistory = map {
            { alert => $id, history => $_ }
        } @{ delete $alert->{history} //[] };
        push @history, @alerthistory;

        ( $alert->{data_with_flair},
          $entities ) = $self->flair_alert_data($alert);

        push @allentities, @$entities;

        unless ( $alert->{data_with_flair} ) {
            $alert->{data_with_flair} = $alert->{data};
        }
        @alert_promotions = map {
            { pair  => [ {type => "event", id   => $_, },
                         {type => "alert", id => $alertid }, ],
              when => $alert->{created} // $alert->{updated} }
        } @{ delete $alert->{events} // [] };

        $newalertcol->insert_one($alert);
    }
    push @links, @alert_promotions;

    $href->{alert_count}    = $alert_count;
    $href->{open_count}     = $status{open} // 0;
    $href->{closed_count}   = $status{count} // 0;
    $href->{promoted_count} = $status{promoted} // 0;

    $col->insert_one($href);

    push @links, $self->create_history(@history);
    push @links, $self->create_sources(@sources);
    push @links, $self->create_tags(@tags);
    push @links, $self->create_entities(\@allentities);
    $self->create_links(@links);

    return 1;
}

sub xform_handler {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $start   = delete $href->{date};
    my $end     = DateTime->new(
        year    => $start->year,
        month   => $start->month,
        day     => $start->day,
        hour    => 23,
        minute  => 59,
        second  => 59,
        time_zone => "Etc/UTC",
    );

    my $name            = delete $href->{user};
    $href->{start}      = $start->epoch;
    $href->{end}        = $end->epoch;
    $href->{username}   = $name;
    delete $href->{groups};

    $col->insert_one($href);
    return 1;
}

sub xform_file {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my @links   = ();

    $href->{directory} = delete $href->{dir};
    push @links, (
        { type  => "entry", id => delete $href->{entry_id} },
        { type  => delete $href->{target_type}, id => delete $href->{target_id}}
    );

    $col->insert_one($href);
    $self->create_links(@links);
    return 1;
}

sub xform_user {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    delete $href->{groups};
    if ( $href->{hash} ) {
        $href->{pwhash} = delete $href->{hash};
    }
    $href->{last_login_attempt} = $href->{lastvisit};

    $col->insert_one($href);
    return 1;
}

sub xform_guide {
    my $self    = shift;
    my $col     = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;


    my $guide   = delete $href->{guide};
    $href->{applies_to} = [ $guide ];

    $col->insert_one($href);
    return 1;
}

sub create_links {
    my $self    = shift;
    my @links   = @_;
    my $linkcol = $self->db->get_collection('link');
    my $env     = $self->env;
    my $log     = $env->log;

    return if (scalar(@links) < 1);

    my $timer   = $env->get_timer("[Links] Bulk created ");
    my $bulk    = $linkcol->initialize_unordered_bulk_op;

    foreach my $href (@links) {
        $href->{id} = $self->get_next_id('link');
        $bulk->insert_one($href);
    }

    my $result = try {
        $bulk->execute;
    }
    catch {
        if ( $_->isa("MongoDB::WriteConcernError") ) {
            warn "Write concern failed";
        }
        else {
            $log->error("Error: $_");
        }
    };
    &$timer;
}

sub get_max_id {
    my $self    = shift;
    my $name    = shift;
    my $col     = $self->db->get_collection($name);
    my $cursor  = $col->find();
    $cursor->sort({id => -1});
    my $doc     = $cursor->next;
    return $doc->{id};
}

sub create_history {
    my $self    = shift;
    my @history = @_;
    my $env     = $self->env;
    my $log     = $env->log;
    my $col     = $self->db->get_collection('history');
    my $timer   = $env->get_timer("[history] Bulk created ");
    my $bulk    = $col->initialize_unordered_bulk_op;
    my @links   = ();

    return () if (scalar(@history) < 1);

    foreach my $h (@history) {
        my $data;
        my $type;
        my $id;
        foreach my $k (keys %$h) {
            if ($k eq "history") {
                $data = $h->{$k};
            }
            else {
                $type   = $k;
                $id     = $h->{$k};
            }
        }

        $data->{when} = int($data->{when});
        $data->{id}   = $self->get_next_id('history');
        $bulk->insert_one($data);
        push @links, {
            pair    => [
                { id    => $data->{id}, type => 'history' },
                { id    => $id,         type => $type },
            ],
            when    => $data->{when},
        };
    }
    my $result = try {
        $bulk->execute;
    }
    catch {
        if ( $_->isa("MongoDB::WriteConcernError") ) {
            warn "Write concern failed";
        }
        else {
            $log->error("Error: $_");
        }
    };
    &$timer;
    return @links;
}

sub create_sources {
    my $self    = shift;
    my @sources = @_;
    my $env         = $self->env;
    my $log         = $env->log;
    my $col         = $self->db->get_collection('source');
    my $timer       = $env->get_timer("[source] Bulk create");
    my $bulk        = $col->initialize_unordered_bulk_op;
    my @links       = ();

    return () if (scalar(@sources) < 1);
    my $insertions  = 0;

    foreach my $h (@sources) {
        my ($data, $type, $id );
        foreach my $k (keys %$h) {
            if ( $k eq "source" ) {
                $data = $h->{$k};
            }
            else {
                $type   = $k;
                $id     = $h->{$k};
            }
        }
        if ( ref($data) eq "ARRAY" ) {
            $data = pop $data;
        }
        
        my $doc = $col->find_one({ value => $data->{value} });
        my $docid;
        unless ($doc) {
            $docid  = $self->get_next_id('source');
            $data->{id} = $docid;
            $bulk->insert_one($data);
            $insertions++;
        }
        else {
            $docid  = $doc->{$id};
        }

        push @links, {
            pair    => [
                { id    => $docid, type => 'source' },
                { id    => $id,      type   => $type },
            ],
            when    => 1,
        };
    }
    if ( $insertions > 0 ) {
        my $result = try {
            $bulk->execute;
        }
        catch {
            if ( $_->isa("MongoDB::WriteConcernError") ) {
                warn "Write concern failed";
            }
            else {
                $log->error("Error Inserting Bulk Sources: $_.  Data =", {filter=>\&Dumper,value=>\@sources});
            }
        };
    }
    &$timer;
    return @links;
}

sub create_tags {
    my $self    = shift;
    my @tags    = @_;
    my $env         = $self->env;
    my $log         = $env->log;
    my $col         = $self->db->get_collection('tag');
    my $timer       = $env->get_timer("[tag] Bulk create");
    my $bulk        = $col->initialize_unordered_bulk_op;
    my @links       = ();
    my $insertions  = 0;

    return () if (scalar(@tags) < 1);

    foreach my $h (@tags) {
        my ($data, $type, $id );
        foreach my $k (keys %$h) {
            if ( $k eq "tag" ) {
                $data = $h->{$k};
            }
            else {
                $type   = $k;
                $id     = $h->{$k};
            }
        }
        if ( ref($data) eq "ARRAY" ) {
            $data = pop $data;
        }

        my $docid;
        my $doc = $col->find_one({ value => $data->{value} });
        unless ( $doc ) {
            $docid  = $self->get_next_id('tag');
            $data->{id} = $docid;
            $bulk->insert_one($data);
            $insertions++;
        }
        else {
            $docid  = $doc->{id};
        }
        push @links, {
            pair    => [
                { id    => $docid,   type => 'tag' },
                { id    => $id,      type => $type },
            ],
            when    => 1,
        };
    }
    if ( $insertions > 0) {
        my $result = try {
            $bulk->execute;
        }
        catch {
            if ( $_->isa("MongoDB::WriteConcernError") ) {
                warn "Write concern failed";
            }
            else {
                $log->error("Error: $_");
            }
        };
    }
    &$timer;
    return @links;

}

sub create_entities {
    my $self        = shift;
    my $entities    = shift; # should be array ref
    my $env         = $self->env;
    my $log         = $env->log;
    my @links       = ();
    my $insertions  = 0;

    $log->debug("entities are ",{filter=>\&Dumper, value=>$entities});

    return () unless ( defined $entities );
    return () if ( scalar(@$entities) < 1 );


    my $timer   = $env->get_timer("[Entities] Create Time");

    my $col     = $self->db->get_collection('entity');
    my $bulk    = $col->initialize_unordered_bulk_op;

    foreach my $entity (@{ $entities }) {
        my $id;
        my $existing = $col->find_one({
            value   => $entity->{value},
            type    => $entity->{type},
        });
        unless ( $existing ) {
            $entity->{id}   = $self->get_next_id('entity');
            my $res = $bulk->insert_one($entity);
            $id = $entity->{id};
            $insertions++;
        }
        else {
            $id = $existing->{id};
        }
        my @targets = @{delete $entity->{targets} };
        foreach my $aref ( @targets ) {
            my $tid     = $aref->{id};
            my $ttype   = $aref->{type};

            my $link    = {
                pair    => [
                    { id    => $id, type => 'entity' },
                    { id    => $tid, type => $ttype   },
                ],
                when    => $entity->{when},
            };
            push @links, $link;
        }
    }
    if ( $insertions > 0 ) {
        my $result = try {
            $bulk->execute;
        }
        catch {
            if ( $_->isa("MongoDB::WriteConcernError") ) {
                warn "Write concern failed";
            }
            else {
                $log->error("Error: $_");
            }
        };
    }
    my $elapsed = &$timer;
    return @links;
}

sub get_next_item {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $item;
    $log->debug("Fetching next item...");
    try {
        $item = $cursor->next;
    }
    catch {
        $log->error("ERROR fetching next item: $_");
        say "Error retrieving item: $_";
        return "skip";
    };
    return $item;
}

sub lookup_legacy_colname {
    my $self    = shift;
    my $type    = shift;
    my %map     = (
        alert       => "alerts",
        alertgroup  => "alertgroups",
        event       => "events",
        entry       => "entries",
        incident    => "incidents",
        handler     => "incident_handler",
        guide       => "guides",
        user        => "users",
        file        => "files",
    );
    return $map{$type};
}

sub calc_rate_eta {
    my $self    = shift;
    my $elapsed = shift;
    my $remain  = shift;
    my $rate    = 0;
    my $eta     = "999999999999";

    if ( $elapsed > 0 ) {
        $rate = ( 1 / $elapsed );
    }
    if ( $rate >  0 ) {
        $eta    = ( $remain / $rate )/3600;
    }
    return $rate, $eta;
}

sub commify {
    my $self    = shift;
    my $number  = shift;
    my $text    = reverse $number;
    $text       =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

sub flair_alert_data {
    my $self    = shift;
    my $alert   = shift;
    my $id      = $alert->{id} // $alert->{alert_id};
    my $data    = $alert->{data};
    my @entities    = ();
    my %flair;
    my %seen;
    my $when    = $alert->{when} // $alert->{create};
    my $env     = $self->env;
    my $log     = $env->log;

    die "unknown alert id! ".Dumper($alert) unless ($id);

    # $log->debug("flairing: ",{filter=>\&Dumper, value=>$alert});
    $log->debug("flairing: ");

    my $timer = $self->env->get_timer("[Alert $id] Flair");

    TUPLE:
    while ( my ($key, $value) = each %{$data} ) {
        unless ( $value ) {
            $log->error("[Alert $id] ERROR Key $key with no Value!");
            next TUPLE;
        }
        my $encoded = '<html>' . encode_entities($value) . '</html>';
        if ( $key =~ /^message_id$/i ) {
            push @entities, { 
                value   => $self->strip_flair($value), 
                type    => "message_id" ,
                targets    => [
                    {   type => 'alert', id => $id },
                    {   type => 'alertgroup', id => $alert->{alertgroup} },
                ],
            };
            next TUPLE;
        }

        my $href    = $self->extractor->process_html($encoded);
        $flair{$key}    = $href->{flair};

        foreach my $entityhref ( @{$href->{entities}} ) {
            my $v   = $entityhref->{value};
            my $t   = $entityhref->{type};
            $entityhref->{when} = $when;
            $entityhref->{targets} = [
                { type => 'alert', id => $id },
                { type => 'alertgroup', id => $alert->{alertgroup} },
            ];
            unless ( defined $seen{$v} ) {
                push @entities, $entityhref;
                $seen{$v}++;
            }
        }
    }
    my $flairsize = length( Dumper(\%flair) );
    my $elapsed = &$timer;
    if ($flairsize > 1000000) {
        $self->env->log->error("[Alert $id] ERROR flair command is too large");
        return;
    }
    $log->debug("Found ".scalar(@entities). " entities", {filter=>\&Dumper, value=>\@entities});
    $log->debug("Flair is ",{filter=>\&Dumper, value=>\%flair});
    return \%flair, \@entities;
}

sub flair_entry_data {
    my $self    = shift;
    my $href    = shift;
    my $id      = $href->{id} // $href->{entry_id};
    my $env     = $self->env;
    my $log     = $env->log;
    my @entities    = ();
    my %flair       = ();
    my %seen        = ();
    my $when        = $href->{when} // $href->{create};
    
    my $timer   = $env->get_timer("[Entry $id] Flair");
    my $flair   = $self->extractor->process_html($href->{body});

    foreach my $entityhref (@{$flair->{entities}}) {
        $entityhref->{when}     = $when;
        $entityhref->{targets}  = [
            { type => 'entry', id => $id },
            { type => $href->{target_type}, id => $href->{target_id} },
        ];
        unless ( defined $seen{$entityhref->{value}} ) {
            push @entities, $entityhref;
            $seen{$entityhref->{value}}++;
        }
    }

    my $elapsed = &$timer;
    return $flair->{flair}, $flair->{text}, \@entities;
}


sub strip_flair {
    my $self    = shift;
    my $flaired = shift;
    my $tree    = HTML::TreeBuilder->new();
       $tree->parse_content($flaired);

    my $element = $tree->look_down( _tag => 'span' );
    return '' unless (defined $element);
    return $element->as_trimmed_text;
}

sub get_next_id {
    my $self        = shift;
    my $collection  = shift;
    my %command;
    my $tie         = tie(%command, "Tie::IxHash");
    %command        = (
        findAndModify   => "nextid",
        query           => { for_collection => $collection },
        update          => { '$inc' => { last_id => 1 } },
        'new'           => 1,
        upsert          => 1,
    );

    my $output  = $self->db->run_command(\%command);
    my $id      = $output->{value}->{last_id};
    return $id;
}

sub lookup_idfield {
    my $self        = shift;
    my $collection  = shift;
    my %map         = (
        alert       => "alert_id",
        alertgroup   => "alertgroup_id",
        event       => "event_id",
        entry       => "entry_id",
        incident    => "incident_id",
        guide       => "guide_id",
        user        => "user_id",
        file        => "file_id",
    );

    return $map{$collection};
}

sub get_pct {
    my $self    = shift;
    my $remain  = shift;
    my $total   = shift;

    my $numerator   = $total - $remain;
    if ( $total > 0 ) {
        return int(($numerator/$total)*10000)/100;
    }
    return "";
}

sub get_unneeded_fields {
    my $self        = shift;
    my $collection  = shift;
    my %unneeded    = (
        alert   => [ qw(_id collection data_with_flair searchtext entities scot2_id 
                        triage_ranking triage_feedback triage_probs
                        disposition downvotes upvotes) ],
        alertgroup  => [ qw( _id collection closed searchtext files scot2_id downvotes upvotes open promoted) ],
        event       => [ qw( _id collection ) ],
        incident    => [ qw( _id collection ) ],
        entry       => [ qw( _id collection body_flaired body_plaintext) ],
        handler     => [ qw( _id parsed )],
        guide       => [ qw( _id history )],
        user        => [ qw( _id display_orientation theme tzpref flair last_activity_check) ],
        file        => [ qw( _id scot2_id fullname )],
    );
    return $unneeded{$collection};
}

        

1;





