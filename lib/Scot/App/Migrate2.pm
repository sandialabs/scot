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

        my $colname     = $self->lookup_legacy_colname($mtype);
        my $legcol      = $self->legacydb->get_collection($colname);
        my $legcursor   = $legcol->find({
            $idfield    => {
                '$gte'  => $id_range->[0],
                '$lte'  => $id_range->[1],
            }
        });
        $legcursor->immortal(1);
        my $remaining_docs  = $legcursor->count();
        my $migrated_docs   = 0;
        my $total_docs      = $remaining_docs;

        ITEM:
        while ( my $item = $self->get_next_item($legcursor) ) {

            if ( $item  eq "skip" ) {
                $migrated_docs++;
                next;
            }

            my $timer   = $env->get_timer("[$mname ".$item->{$idfield}.
                            "] Migration");
            
            my $pct = $self->get_pct($remaining_docs, $total_docs);
            
            unless ( $self->transform($mtype, $item) ) {
                $log->error("Error: $mtype Transform failed ",
                            { filter => \&Dumper, value=> $item });
            }
            
            my $elapsed = &$timer;
            $remaining_docs--;
            $migrated_docs++;
            my ($rate, $eta) = $self->calc_rate_eta($elapsed, $remaining_docs);

            my $ratestr = sprintf("%5.3f docs/sec", $rate);
            my $etastr  = sprintf("%5.3f hours", $eta);
            my $elapstr = sprintf("%5.2f", $elapsed);
            if ($opts->{verbose} ) {
                my $postspace   = 4 - $procindex;
                say " "x$procindex .$procindex.
                    " "x$postspace.": [ $mname ". $item->{id}.
                    "] $elapstr secs -- $ratestr $etastr ".
                    $self->commify($remaining_docs). " remain";
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
            }
            push @ids, [ $range[0], $range[-1] ];
            @range = ();
        }
    }

    $self->env->log->debug("$mtype idranges ",{filter=>\&Dumper, value=>\@ids});

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
            read    => delete $item->{readgroups} // $self->default_read,
            modify  => delete $item->{modifygroups} // $self->default_modify,
        };
    }

    $log->trace("[$mtype $id] removing unneeded fields");
    foreach my $attribute ( @{ $self->get_unneeded_fields($mtype) }) {
        delete $item->{$attribute};
    }

    return $self->$method($newcol, $item);

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
        { alertgroup => $id, tag => $_ }   
    } @{ delete $href->{tags} //[] };
    my @sources = map {
        { alertgroup => $id, source => $_ }
    } @{ delete $href->{sources} //[] };

    $href->{body}        = delete $href->{body_html};
    $href->{body_plain}  = delete $href->{body_plain};


    my $newalertcol     = $self->db->get_collection('alert');
    my $leg_alert_col   = $self->legacydb->get_collection('alerts');
    my $leg_alert_cursor= $leg_alert_col->find({alertgroup => $id});
    $leg_alert_cursor->immortal(1);
    my $alert_count     = $leg_alert_cursor->count();
    my $entities;
    my @alert_promotions    = ();
    my %status;

    ALERT:
    while ( my $alert = $leg_alert_cursor->next ) {
        my $alertid     = $alert->{alert_id};
        $alert->{id}    = delete $alert->{alert_id};
        $status{$alert->{status}}++;
        $log->trace("[alert $alertid] removing unneeded fields");
        foreach my $attribute ( @{ $self->get_unneeded_fields('alert') }) {
            delete $href->{$attribute};
        }
        if ( $alert->{updated} ) {
            $alert->{updated}    = int($alert->{updated});
        }

        if ( $alert->{readgroups} ) {
            $alert->{groups} = {
                read    => delete $href->{readgroups} // $self->default_read,
                modify  => delete $href->{modifygroups} // $self->default_modify,
            };
        }
        ( $alert->{data_with_flair},
          $entities ) = $href->{data};
        unless ( $href->{data_with_flair} ) {
            $href->{data_with_flair} = $href->{data};
        }
        @alert_promotions = map {
            { pair  => [ {type => "event", id   => $_, },
                         {type => "alert", id => $alertid }, ],
              when => $href->{created} // $href->{updated} }
        } @{ delete $href->{events} // [] };
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
    push @links, $self->create_entities($entities);
    $self->create_links(@links);

    return 1;
}

sub create_links {
    my $self    = shift;
    my @links   = @_;
    my $linkcol = $self->db->get_collection('link');
    my $env     = $self->env;
    my $log     = $env->log;
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
        $bulk->insert_one($data);
        push @links, {
            pair    => [
                { id    => $self->get_next_id('history'), type => 'history' },
                { id    => $id,      type => $type },
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
        $bulk->insert_one($data);
        push @links, {
            pair    => [
                { id    => $self->get_next_id('source'), type => 'source' },
                { id    => $id,      type   => $type },
            ],
            when    => 1,
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

sub create_tags {
    my $self    = shift;
    my @tags    = @_;
    my $env         = $self->env;
    my $log         = $env->log;
    my $col         = $self->db->get_collection('tag');
    my $timer       = $env->get_timer("[tag] Bulk create");
    my $bulk        = $col->initialize_unordered_bulk_op;
    my @links       = ();

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
        $bulk->insert_one($data);
        push @links, {
            pair    => [
                { id    => $self->get_next_id('tag'), type => 'tag' },
                { id    => $id,      type   => $type },
            ],
            when    => 1,
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

sub create_entities {
    my $self        = shift;
    my $entities    = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my @links       = ();

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
    my $elapsed = &$timer;
    return @links;
}

sub get_next_item {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $item;
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
    my $id      = $alert->{id};
    my $data    = $alert->{data};
    my @entities    = ();
    my %flair;
    my %seen;
    my $when    = $alert->{when} // $alert->{create};

    my $timer = $self->env->get_timer("[Alert $id] Flair");

    TUPLE:
    while ( my ($key, $value) = each %{$data} ) {
        my $encoded = '<html>' . encode_entities($value) . '</html>';
        if ( $key =~ /^message_id$/i ) {
            push @entities, { value => $value, type => "message_id" };
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
    return \%flair, \@entities;
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

1;





