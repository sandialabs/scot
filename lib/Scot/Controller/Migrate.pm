package Scot::Controller::Migrate;

use lib '../../../lib';

=head1 Name

Scot::Controller::Migrate

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

sub _get_legacy_db {
    my $self    = shift;
    # return $self->legacy_client->get_database('scotng-prod');
    return MongoDB->connect->db('scotng-prod');
}

sub migrate  {
    my $self    = shift;
    my $mtype   = shift;
    my $mname   = ucfirst($mtype);
    my $opts    = shift;        # href
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat

    my $collection_timer    = $env->get_timer("[$mname] Migration");
    my $starting_id         = $self->get_starting_id($mtype);

    $log->debug("===\n".
        " " x57 . "=== Beginning $mname Migration\n".
        " " x57 . "=== Last Migrated $mname: $starting_id\n".
        " " x57 . "=== mtype = $mtype\n".
        " " x57 . "===");

    if ( $opts->{verbose} ) {
        say "===";
        say "=== Beginning $mname Migration";
        say "=== Last Migrated $mname: $starting_id";
        say "===";
    }

    my %legacy_collections = (
        alert       => "alerts",
        alertgroup   => "alertgroups",
        event       => "events",
        entry       => "entries",
        incident    => "incidents",
    );
    my %legacy_idfields = (
        alert       => "alert_id",
        alertgroup   => "alertgroup_id",
        event       => "event_id",
        entry       => "entry_id",
        incident    => "incident_id",
    );

    my $legacy_col_name = $legacy_collections{$mtype};

    $log->debug("Getting legacy collection $legacy_col_name");

    my $legacy_collection   = $self->legacydb->get_collection($legacy_col_name);
    my $legacy_cursor       = $legacy_collection->find({ $legacy_idfields{$mtype} => {'$gte' => $starting_id} });
    $legacy_cursor->immortal(1);

    $log->debug("Got legacy cursor");

    my $remaining_docs  = $legacy_cursor->count();
    my $migrated_docs   = $starting_id;


    while ( my $item = $legacy_cursor->next ) {   # event is a href

        my $timer   = $env->get_timer("[$mname ".$item->{$legacy_idfields{$mtype}}."] Migration");
        my $pct = $self->get_pct($remaining_docs, $migrated_docs);
        $log->debug("[$mname] Remaining: $remaining_docs Migrated: $migrated_docs Pct: ".
                    sprintf("%5.4f",$pct));
        if ( $opts->{verbose} ) {
            say "[$mname] Remaining: ". 
                $self->commify($remaining_docs) .
                " Migrated: ".
                $self->commify($migrated_docs) .
                " Pct: ". sprintf("%5.4f",$pct);
        }

        my $href = $self->transform($mtype, $item);

        next unless($href);

        my $object;
        try {
            $object  = $mongo->collection($mname)->exact_create($href->{$mtype});
        }
        catch {
            $log->error("[$mname $href->{id}] Error: Failed migration!");
            if ( $opts->{verbose} ) {
                say "[$mname $href->{id}] ERROR = failed migration";
            }
            next;
        };

        unless ( $object ) {
            $log->error("[$mname $href->{id}] ERROR: failed to create!");
            die "Failed to create object from ".Dumper($href->{$mtype});
        }

        $self->do_linkables($object,$href);

        my $elapsed = &$timer;
        $remaining_docs--;
        $migrated_docs++;
        my ($rate, $eta)    = $self->calc_rate_eta($elapsed, $remaining_docs);
        my $ratestr = sprintf("%5.3f d/sec", $rate);
        my $etastr  = sprintf("%5.3f hours", $eta);
        $log->debug("[$mname ".$object->id."] $ratestr $etastr");
        if ( $opts->{verbose} ) {
            say "[$mname ".$object->id."] ".
            sprintf("%5.2f",$elapsed) . " seconds  -- $ratestr $etastr";
        }
    }
}

sub transform {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat
    my %unneeded    = (
        alert   => [ qw( _id    collection 
                        data_with_flair     searchtext 
                        entities scot2_id   triage_ranking 
                        triage_feedback     triage_probs 
                        disposition downvotes upvotes) ],
        alertgroup  => [ qw( _id collection closed ) ],
        event       => [ qw( _id collection ) ],
        incident    => [ qw( _id collection ) ],
        entry       => [ qw( _id collection body_flaired body_plaintext) ],
    );

    my %legacy_idfields = (
        alert       => "alert_id",
        alertgroup   => "alertgroup_id",
        event       => "event_id",
        entry       => "entry_id",
        incident    => "incident_id",
    );

    my $idfield     = delete $href->{idfield};

    unless ($idfield) {
        $idfield = $legacy_idfields{$type};
    }

    my $id          = delete $href->{$idfield};

    die "No ID! ".Dumper($href) unless ($id);

    $href->{id}     = $id;

    $log->debug("[$type $id] transformation");
    my $timer   = $env->get_timer("[$type $id] Transform");

    foreach my $attribute ( @{ $unneeded{$type} } ) {
        delete $href->{$attribute};
    }

    my @history;
    if ( $href->{history} ) {
        @history = @{ delete $href->{history}};
    }
    my @tags;
    if ( $href->{tags} ) {
        @tags = @{ delete $href->{tags}};
    }
    my @sources;
    if ( $href->{sources} ) {
        @sources = @{ delete $href->{sources}};
    }
    my @promos;  
                

    my $entity_aref;
    $href->{parsed}    = 0;

    if ( $type eq "alert" ) {
        ($href->{data_with_flair},
         $entity_aref )             = $self->flair_alert_data($href);
        $href->{data_with_flair} = $href->{data} unless ( $href->{data_with_flair} );
        @promos = map { 
            { type => "event", id => $_, when => $href->{created} // $href->{updated} } 
        } @{ delete $href->{events} // [] };
    }
    if ( $type eq "alertgroup" ) {
        @promos = map { { type => "event", id => $_, when => $href->{created}//$href->{updated} } } 
                  @{ delete $href->{events} // [] };
        if ( $href->{status} =~ /\// ) {
            if ( defined $href->{promoted_count} and $href->{promoted_count} > 0 ) {
                $href->{status}   = "promoted";
            }
            elsif ( defined $href->{open_count} and $href->{open_count} > 0 ) {
                $href->{status}   = "open";
            }
            else {
                $href->{status}   = "closed";
            }
        }
        if ( $href->{status} eq "revisit" ) {
            $href->{status} = "closed";
        }
        $href->{total}            = delete $href->{alert_count} // 0;        
        $href->{open_count}       = delete $href->{open} // 0;        
        $href->{closed_count}     = delete $href->{closed} // 0;        
        $href->{promoted_count}   = delete $href->{promoted} // 0;        
    }
    if ( $type  eq "event" ) {
        push @promos, map { {type=>"alert", id=>$_, when=>$href->{created} } } 
            @{ delete $href->{alerts} };
        push @promos, map { {type=>"incident", id=>$_, when=>$href->{created}} }
            @{ delete $href->{incidents} };

        $href->{views}      = delete $href->{view_count};
        $href->{viewed_by}  = delete $href->{viewed_by};
    }

    if ( $type eq "incident" ) {
        push @promos, map { 
            { type => "event", id => $_, when => $href->{created}//$href->{updated} } 
        } @{ delete $href->{events} // [] };
        
        unless ( defined $href->{owner} ) {
            $href->{owner} = "unknown";
        }
    }

    if ( $type eq "entry" ) {

        if ( length($href->{body} ) > 2000000 ) {
            $log->warn("[$type $id] HUGE BODY! Saving for later splitting");
            $self->handle_huge_entry($id);
            return undef;
        }

        if ( ref($href->{body}) eq "MongoDB::BSON::Binary" ) {
            $href->{body} = "<html>".$href->{plaintext}."</html>";
        }

        ( $href->{body_flair},
          $href->{body_plain},
          $entity_aref  )   = $self->flair_entry_data($href);

        $href->{parent} = 0 unless ($href->{parent});

        push @promos, { type => delete $href->{target_type}, id => delete $href->{target_id}, when => $href->{created} };

    }

    $href->{updated}    = int($href->{updated});  # some old versions had decimals
    $href->{groups}     = {
        read    => delete $href->{readgroups} // $self->default_read,
        modify  => delete $href->{modifygroups} // $self->default_modify,
    };

    my $xform   = {
        $type   => $href,
        history => \@history,
        tags    => \@tags,
        sources => \@sources,
        promos  => \@promos,
        entity  => $entity_aref
    };

    my $elapsed = &$timer;
    return $xform;
}

sub handle_huge_entry {
    my $self    = shift;
    my $id      = shift;
    open my $out, ">>", "/tmp/huge.entries.txt";
    print $out $id."\n";
    close $out;
}
    

sub get_pct {
    my $self    = shift;
    my $denom   = shift;
    my $x       = shift;

    my $numerator   = $denom - $x;
    if ( $denom > 0 ) {
        return 100 - int( ($numerator/$denom)*100000 )/1000;
    }
    return "";
}

sub get_starting_id {
    my $self    = shift;
    my $type    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $cursor  = $mongo->collection(ucfirst($type))->find({});
    $cursor->sort({id => -1});
    my $object  = $cursor->next;
    unless ($object) {
        return 0;
    }
    return $object->id;
}

sub do_linkables {
    my $self    = shift;
    my $object  = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $historycol  = $mongo->collection('History');
    foreach my $history (@{ $href->{history} }) {
        next unless $history;
        $history->{when} = int($history->{when});
        try {
            my $hobj = $historycol->create($history);
            $self->link($object, $hobj);
        }
        catch {
            $log->error("[".$object->get_collection_name." ".$object->id."] Failed History create ",
                { filter => \&Dumper, value => $history } );
        };
    }

    my $srccol  = $mongo->collection('Source');
    foreach my $source  (@{ $href->{sources}} ) {
        if ( ref($source) eq "ARRAY" ) {
            $source = pop $source;
        }
        my $sobj    = $srccol->find_one({ value => $source });
        unless ($sobj) {
            $sobj   = $srccol->create({ value   => $source });
        }
        $self->link($object, $sobj);
    }

    my $tagcol  = $mongo->collection('Tag');
    foreach my $tag     (@{ $href->{tags}} ) {
        my $tobj    = $tagcol->find_one({value => $tag});
        unless ($tobj) {
            $tobj   = $tagcol->create({value=> $tag});
        }
        $self->link($object, $tobj);
    }

    my $linkcol = $mongo->collection('Link');
    foreach my $promo   (@{ $href->{promos}}) {
        my $type    = $promo->{type};
        my $id      = $promo->{id};
        my $when    = $promo->{when} // $env->now;

        if  (ref($id) eq "MongoDB::OID") {
            my $icol    = $self->legacydb->get_collection('incidents');
            my $href    = $icol->find_one({events   => $object->id});
            $log->debug("Weird OID incident ref in event detected. Now using ",{filter=>\&Dumper,value=>$href});
            $id     = $href->{incident_id};
            unless ( $id ) {
                $log->error("unable to find matching oid to id, skipping");
                next;
            }
        }

        my $la  = $linkcol->create({
            item_type   => $type,
            item_id     => $id,
            when        => $when,
            target_type => $object->get_collection_name,
            target_id   => $object->id,
        });
        my $lb  = $linkcol->create({
            target_type   => $type,
            target_id     => $id,
            when        => $when,
            item_type => $object->get_collection_name,
            item_id   => $object->id,
        });
    }
}

sub link {
    my $self    = shift;
    my $obja    = shift;
    my $objb    = shift;
    my $env     = $self->env;
    my $when    = shift // $env->now;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $linkcol = $mongo->collection('Link');

    my $la  = $linkcol->create({
        item_type   => $obja->get_collection_name,
        item_id     => $obja->id,
        when        => $when,
        target_type => $objb->get_collection_name,
        target_id   => $objb->id,
    });
    my $lb  = $linkcol->create({
        item_type   => $objb->get_collection_name,
        item_id     => $objb->id,
        when        => $when,
        target_type => $obja->get_collection_name,
        target_id   => $obja->id,
    });


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

sub flair_entry_data {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $id      = $href->{id};
    my $timer   = $env->get_timer("[Entry $id] Flairing");
    my $flair   = $self->extractor->process_html($href->{body});
    my $elapsed = &$timer;
    return $flair->{flair}, $flair->{text}, $flair->{entities};
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

1;
