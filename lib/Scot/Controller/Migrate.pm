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


sub handle_huge_entry {
    my $self    = shift;
    my $id      = shift;
    open my $out, ">>", "/tmp/huge.entries.txt";
    print $out $id."\n";
    close $out;
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
    my $timer   = $env->get_timer("[".$object->get_collection_name.
                                  " ".$object->id."] creating linkables");

    my $entitycol   = $mongo->collection('Entity');
    my $linkcol     = $mongo->collection('Link');

    foreach my $entity (@{ $href->{entity} }) {
        # entity = { value => , type => }
        next unless $entity;

        $log->debug("working on entity {".$entity->{value}.
                    ",".$entity->{type}."}");

        my $when    = $object->when // $object->created;

        my $eobj    = $entitycol->find_one({
            value => $entity->{value}, 
            type => $entity->{type}
        });

        unless ( $eobj ) {
            $log->debug("Entity is new, creating...");
            $eobj   = $entitycol->create($entity);
        }
        
        $log->debug("creating links...");
        my $la  = $linkcol->create_link(
            { type => "entity",                     id => $eobj->id, },
            { type => $object->get_collection_name, id   => $object->id, },
            $when,
        );

        if ( defined $entity->{ltype} ) {
            # we have an entry object and we are going to create links
            # to the object that the entry is associated with
            my $hla = $linkcol->create_link(
                {type => "entity",          id   => $eobj->id, },
                {type => $entity->{ltype},  id   => $entity->{lid}, },
                $entity->{when},
            );
        }
    }

    my $historycol  = $mongo->collection('History');
    foreach my $history (@{ $href->{history} }) {
        next unless $history;
        $history->{when} = int($history->{when});
        try {
            my $hobj = $historycol->create($history);
            $self->link($object, $hobj);
        }
        catch {
            $log->error("[".$object->get_collection_name.
                        " ".$object->id."] Failed History create ",
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

    foreach my $link   (@{ $href->{links}}) {

        my $type    = $link->{type};
        my $id      = $link->{id};
        my $when    = $link->{when} // $env->now;

        if  (ref($id) eq "MongoDB::OID") {
            my $icol    = $self->legacydb->get_collection('incidents');
            my $href    = $icol->find_one({events   => $object->id});

            $log->debug("Weird OID incident ref in event detected. Now using ",
                        {filter=>\&Dumper,value=>$href});

            $id     = $href->{incident_id};
            unless ( $id ) {
                $log->error("unable to find matching oid to id, skipping");
                next;
            }
        }

        my $la  = $linkcol->create_link(
            {type => $type,                         id   => $id, },
            {type => $object->get_collection_name,  id   => $object->id,},
            $when,
        );
    }
    my $elapsed = &$timer;
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

    my $la  = $linkcol->create_link(
        { type  => $obja->get_collection_name, id => $obja->id, },
        { type  => $objb->get_collection_name, id => $objb->id, },
        $when
    );
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

sub get_id_r2 {
    my $self    = shift;
    my $mtype   = shift;
    my $numproc = shift;
    my $opts    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $starting_id = $self->get_starting_id($mtype);
    my $idfield     = $self->lookup_idfield($mtype);
    my $colname     = $self->lookup_legacy_colname($mtype);
    my $collection  = $self->legacydb->get_collection($colname);

    my @ids     = ();
    my @range   = ();

    my $cursor      = $collection->find();
    my $tomigrate   = $cursor->count();

    my $chunksize   = int ($tomigrate / $numproc);

    say "$tomigrate docs to migrate";
    say "$chunksize docs per process";

    my $startid = 0;
    my $endid   = 0;
    my $skip     = 0;

    while ( $endid < $tomigrate ) {
        my $skip += $chunksize;
        my $cursor = $collection->find();
        say "skipping $skip";
        $cursor->skip($skip);
        my $obj = $cursor->next;
        last unless $obj;
        $endid = $obj->{$idfield};
        say "start = $startid end = $endid";
        push @range, [ $startid, $endid ];
        $startid = $endid + 1;
    }
    say "Found these ranges ".Dumper(@range);
    die;
}


sub get_id_ranges{
    my $self    = shift;
    my $mtype   = shift;
    my $numproc = shift;
    my $opts    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $starting_id = $self->get_starting_id($mtype);
    my $idfield     = $self->lookup_idfield($mtype);
    my $colname     = $self->lookup_legacy_colname($mtype);
    my $collection  = $self->legacydb->get_collection($colname);

    my @ids     = ();
    my @range   = ();

    
    if ( $numproc == 0 ) {
        my $match;

        if ( $mtype eq "handler" ) {
            $match  = {};
        }
        else {
            $match   = { $idfield => {'$gte'=> $starting_id} };
        }

        $log->debug("numproc 0 so looking for ",{filter=>\&Dumper, value=>$match});

        my $cursor  = $collection->find($match);
        unless ($cursor) {
            $log->error("invalid cursor!");
        }
        if ( $mtype ne "handler" ) {
            $cursor->sort({$idfield => -1});
        }
        my $obj     = $cursor->next;
        unless ($obj) {
            $log->error("undefined object");
        }
        my $max     = $obj->{$idfield};
        push @ids, [ $starting_id, $max ];
        if ( $opts->{verbose} ) {
            say "...Normal single process migration of $mtype from $starting_id to $max";
        }
        return wantarray ? @ids : \@ids;
    }

    my $cursor  = $collection->find({ $idfield => { '$gte' => $starting_id}});
    my $remain  = $cursor->count();
    my $dpp     = int($remain/$numproc);
    if ( $opts->{verbose} ) {
        say "Scanning ". $self->commify($remain). " $colname documents ".
            "for id ranges"; 
    }

    my $count   = 0;


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
    return wantarray ? @ids : \@ids;
}


sub migrate {
    my $self    = shift;
    my $mtype   = shift;
    my $mname   = ucfirst($mtype);
    my $opts    = shift;

    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $num_proc    = $opts->{num_proc}    // 0;
    my $forkmgr     = Parallel::ForkManager->new($num_proc);

    my @idranges    = ();
    if ( $opts->{idranges} ) {
        @idranges = @{$opts->{idranges}};
    }
    else {
        if ( $mtype ne "handler" and $mtype ne "guide" ) {
            @idranges   = $self->get_id_ranges($mtype, $num_proc, $opts);
        }
        else {
            say "skipping idrange check because we are converting $mtype";
            @idranges   = ( [1,100000] );
        }
    }

    my $procindex   = 0;
    my $idfield     = $self->lookup_idfield($mtype);

    PROCGROUP:
    foreach my $id_range ( @idranges ) {
        $forkmgr->start($procindex++) and next PROCGROUP;

            $self->legacy_client->reconnect();
            my $legcol  = $self->legacydb->get_collection(
                $self->lookup_legacy_colname($mtype)
            );

            my $legcursor;

            if ( $mtype ne "guide" and $mtype ne "handler" ) {
                my $start_id    = $id_range->[0];
                my $end_id      = $id_range->[1];

                $legcursor   = $legcol->find({
                    $idfield    => {
                        '$gte'  => $start_id,
                        '$lte'  => $end_id,
                    }
                });
            }
            else {
                $legcursor  = $legcol->find();
            }

            my $remaining_docs  = $legcursor->count();
            my $migrated_docs   = 0;
            my $total_docs      = $remaining_docs;

            say "Starting Migration of $remaining_docs docs";

            ITEM:
            while ( my $item = $legcursor->next ) {
                my $timer   = $env->get_timer(
                    "[$mname ". $item->{$idfield}."] Migration"
                ) if ($mtype ne "handler" and $mtype ne "guide");
                my $pct     = $self->get_pct($remaining_docs, $total_docs);
                my $href    = $self->transform($mtype, $item);
                next unless ($href);
                my $object;
                my $collection  = $mongo->collection($mname);

                unless ( $collection ) {
                    $log->error("Weird not a valid collection!");
                    die "invalid colllection\n";
                }

                try {
                    if ( $mtype eq "handler" or $mtype eq "guide" ) {
                        $object = $collection->create($href->{$mtype});
                    }
                    else {
                        $object = $collection->exact_create($href->{$mtype});
                    }
                }
                catch {
                    $log->error("[$mname $href->{id}] Error: failed migration");
                    if ( $opts->{verbose} ) {
                        say "[$mname $href->{id}] ERROR: Failed Create!";
                    }
                    next ITEM;
                };
                
                unless ($object) {
                    die "didn't create object!\n";
                }


                $self->do_linkables($object, $href);
                my $elapsed = &$timer;
                $remaining_docs--;
                $migrated_docs++;
                my ($rate, $eta)    = $self->calc_rate_eta($elapsed, 
                                                           $remaining_docs);
                my $ratestr = sprintf("%5.3f docs/sec", $rate);
                my $etastr  = sprintf("%5.3f hours", $eta);
                my $elapstr = sprintf("%5.2f", $elapsed);
                if ($opts->{verbose} ) {
                    say "$procindex: [ $mname ". $object->id.
                        "] $elapstr secs -- $ratestr $etastr ".
                        $self->commify($remaining_docs). " remain";
                }
            }
        $forkmgr->finish;
    }
    $forkmgr->wait_all_children;
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

sub get_unneeded_fields {
    my $self        = shift;
    my $collection  = shift;
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
        handler     => [ qw( _id parsed )],
        guide       => [ qw( _id history )],
        user        => [ qw( _id display_orientation theme tzpref flair last_activity_check) ],
        file        => [ qw( _id scot2_id fullname )],
    );
    return $unneeded{$collection};
}

sub transform {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;

    if ( $href->{updated} ) {
        $href->{updated}    = int($href->{updated});
    }
    
    if ( $type eq "handler" ) {
        return $self->xform_handler($href);
    }

    my $idfield = delete $href->{idfield} // $self->lookup_idfield($type);
    my $id      = delete $href->{$idfield};

    $log->debug("[$type $id] transformation");
    my $timer   = $env->get_timer("[$type $id] Transform");


    $href->{id} = $id // '';

    foreach my $attribute ( @{ $self->get_unneeded_fields($type) }) {
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

    if ( $href->{readgroups} ) {
        $href->{groups}     = {
            read    => delete $href->{readgroups} // $self->default_read,
            modify  => delete $href->{modifygroups} // $self->default_modify,
        };
    }

    my $links;
    my $entities;

    if ( $type eq "alert" ) {
        ($links, $entities) = $self->xform_alert($href);
    }

    if ( $type eq "alertgroup" ) {
        $links  = $self->xform_alertgroup($href);
    }

    if ( $type  eq "event" ) {
        $links = $self->xform_event($href);
    }

    if ( $type eq "incident" ) {
        $links  = $self->xform_incident($href);
    }

    if ( $type eq "entry" ) {
        ($links, $entities)  = $self->xform_entry($href);
    }

    if ( $type eq "guide" ) {
        $links  = $self->xform_guide($href);
    }

    if ( $type eq "user" ) {
       $self->xform_user($href);
    }

    if ( $type eq "file" ) {
        $links  = $self->xform_file($href);
    }

    my $xform   = {
        $type   => $href,
        history => \@history,
        tags    => \@tags,
        sources => \@sources,
        links   => $links,
        entity  => $entities,
    };

    my $elapsed = &$timer;
    return $xform;
}

sub xform_handler {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;
    my $start   = delete $href->{date}; # DataTime object
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
}

sub xform_alert {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;
    my $entities;
    my @links;

    ($href->{data_with_flair},
     $entities               ) = $self->flair_alert_data($href);

    unless ( $href->{data_with_flair} ) {
        $href->{data_with_flair} = $href->{data};
    }

    @links = map { 
        { type => "event", 
            id => $_, 
            when => $href->{created} // $href->{updated} } 
    } @{ delete $href->{events} // [] };
    return \@links, $entities;
}

sub xform_alertgroup {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;

    $log->debug("[Alertgroup $href->{id}] xforming ",
                { filter=>\&Dumper, value => $href});

    my @promos = map { 
        { type  => "event", 
            id    => $_, 
            when  => $href->{created}//$href->{updated} } 
    } @{ delete $href->{events} // [] };

    if ( $href->{status} =~ /\// ) {
        if ( defined $href->{promoted_count} and 
                $href->{promoted_count} > 0 ) {
            $href->{status}   = "promoted";
        }
        elsif ( defined $href->{open_count} and 
                $href->{open_count} > 0 ) {
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
    $href->{body}             = delete $href->{body_html};
    $href->{body_plain}       = delete $href->{body_plain};

    return \@promos;
}

sub xform_event {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;
    my @promos;
    push @promos, map { {type=>"alert", id=>$_, when=>$href->{created} } } 
        @{ delete $href->{alerts} };
    push @promos, map { {type=>"incident", id=>$_, when=>$href->{created}} }
        @{ delete $href->{incidents} };

    $href->{views}      = delete $href->{view_count};
    $href->{viewed_by}  = delete $href->{viewed_by};
    return \@promos;
}

sub xform_incident {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;
    my @promos;
    push @promos, map { 
        { type => "event", 
            id => $_, 
            when => $href->{created}//$href->{updated} } 
    } @{ delete $href->{events} // [] };
    
    unless ( defined $href->{owner} ) {
        $href->{owner} = "unknown";
    }
    return \@promos;
}

sub xform_entry {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;
    my @promos; 
    my $entities;
    my $id  = $href->{id};

    if ( length($href->{body} ) > 2000000 ) {
        $log->warn("[entry $id] HUGE BODY! Saving for later splitting");
        $self->handle_huge_entry($id);
        return undef;
    }

    if ( ref($href->{body}) eq "MongoDB::BSON::Binary" ) {
        $href->{body} = "<html>".$href->{plaintext}."</html>";
    }

    ( $href->{body_flair},
        $href->{body_plain},
        $entities  )   = $self->flair_entry_data($href);

    $href->{parent} = 0 unless ($href->{parent});
    $href->{owner}  = "unknown" unless($href->{owner});

    my $target_type = delete $href->{target_type};
    my $target_id   = delete $href->{target_id};

    push @promos, { 
        type    => $target_type, 
        id      => $target_id, 
        when    => $href->{created} 
    };

    # need something here because entities are not linking to the higher
    # object
    foreach my $entity (@{$entities}) {
        $entity->{ltype} = $target_type;
        $entity->{lid}  = $target_id;
        $entity->{when} = $href->{created};
    }
    say "Entry $id had these Entities: ".Dumper($entities);
    return \@promos, $entities;
}

sub xform_file {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;
    my @links;

    $href->{directory}  = delete $href->{dir};
    push @links, (
        { type  => "entry", id  => delete $href->{entry_id} },
        { type  => delete $href->{target_type}, id => delete $href->{target_id}}
    );
    return \@links;
}

sub xform_guide {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;

    my $guide   = delete $href->{guide};
    $href->{applies_to} = [ $guide ];
}
 
sub xform_user {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;  # meerkat;

    delete $href->{groups};
    if ( $href->{hash} ) {
        $href->{pwhash}             = delete $href->{hash};
    }
    $href->{last_login_attempt}  = $href->{lastvisit};
}


1;
