#!/usr/bin/env perl

use lib '../lib';
use Data::Dumper;
use Scot::Env;
use Scot::Util::EntityExtractor;
use HTML::Entities;
use MongoDB;
use Getopt::Long qw(GetOptions);
use Parallel::ForkManager;
use v5.18;

$| = 1;

$ENV{scot_mode} = "prod";
my $env     = Scot::Env->new();
my $meerkat = $env->mongo;
my $log     = $env->log;
my $extractor   = Scot::Util::EntityExtractor->new({ log => $log });

my $doalerts    = 1;
my $doevents    = 1;
my $doincidents = 1;
my $doentry     = 1;
my $startover   = 0;
my $docols      = "alertgroups,events,incidents,entries";

GetOptions( 
    "alert=i"    => \$doalerts,
    "event=i"    => \$doevents,
    "incident=i" => \$doincidents,
    "entry=i"    => \$doentry,
    "startover"  => \$startover,
    "cols=s"     => \$docols,
) or die <<EOF;

    INVALID OPTION

    useage: $0 
        --alert=x   start at alertgroup id of x, 0 skip all alertgroups
        --event=x   start at event id of x, 0 skip all
        --incident=x
        --entry=x
        --docols=colname1,...             do only listed collections
        --startover zero's everything

EOF

if ($startover) {
    system("mongo scot-prod < reset_db.js");
}


my $client       = MongoDB::MongoClient->new();
my $db           = $client->get_database("scotng-prod");
my $alertgroups  = $db->get_collection('alertgroups');
my $alerts       = $db->get_collection('alerts');
my $events       = $db->get_collection('events');
my $incidents    = $db->get_collection('incidents');
my $entries      = $db->get_collection('entries');

my $forkmgr = Parallel::ForkManager->new(4);
$forkmgr->run_on_start(
    sub {
        my ($pid, $ident)   = @_;
        unless ($ident) { $ident = 'na'; }
        $log->trace("[PID $pid] Started");
    }
);
$forkmgr->run_on_wait(
    sub {
        $log->trace("Waiting on Workers");
    }
);

$forkmgr->run_on_finish(
    sub {
        my ($pid, $exit, $ident) = @_;
        $log->trace("[PID $pid] Finished");
    }
);

my %action  = (
    alertgroups => \&process_alertgroups,
    events      => \&process_events,
    incidents   => \&process_incidents,
    entries     => \&process_entries,
);

foreach my $col (split(/,/,$docols)) {
    print "Processing $col\n";
    $forkmgr->start($col) and next;
    $action{$col}->();
    $forkmgr->finish(0);
}

sub get_restart_id {
    my $colname = shift;
    my $cursor  = $meerkat->collection($colname)->find({});
    $cursor->sort({id => -1});
    my $obj     = $cursor->next;
    if ( $obj ) {
        return $obj->id;
    }
    return 0;
}

sub process_alertgroups {

    my $restart_id  = get_restart_id('Alertgroup');
    if ($restart_id == 0) {
        $restart_id = $doalerts;
    }

    my $agcursor     = $alertgroups->find({alertgroup_id    => { '$gte' => $restart_id }});
    $agcursor->immortal(1);

    $log->debug("Processing ". $agcursor->count. " Alertgroups");

    while ( my $alertgroup = $agcursor->next ) {

        my $agid    = delete $alertgroup->{alertgroup_id};
        $log->debug("[Alertgroup ". $agid."] Begins processing");

        delete $alertgroup->{idfield};
        delete $alertgroup->{collection};
        $alertgroup->{id}           = $agid;
        $alertgroup->{body}         = delete $alertgroup->{body_html};
        $alertgroup->{views}        = delete $alertgroup->{view_count};
        $alertgroup->{view_history} = delete $alertgroup->{viewed_by};
        delete $alertgroup->{closed};

        unless ( $alertgroup->{body} ) { $alertgroup->{body} = ' '; }


        $alertgroup->{groups}   = {
            read    => delete $alertgroup->{readgroups},
            modify  => delete $alertgroup->{modifygroups},
        };

        my @sources = @{ delete $alertgroup->{sources} // []};
        my @tags    = @{ delete $alertgroup->{tags} // [] };

        $alertgroup->{promotions}   = { to  => delete $alertgroup->{events} };
        $alertgroup->{total}        = delete $alertgroup->{alert_count} //0;
        $alertgroup->{open_count}   = delete $alertgroup->{open} // 0;
        $alertgroup->{closed_count} = delete $alertgroup->{closed} // 0;
        $alertgroup->{promoted_count} = delete $alertgroup->{promoted}// 0;

        if ( $alertgroup->{status} =~ /\// ) {
            if ( $alertgroup->{promoted_count} > 0 ) {
                $alertgroup->{status} = "promoted";
            }
            elsif ( $alertgroup->{open_count} > 0 ) {
                $alertgroup->{status} = "open";
            }
            else {
                $alertgroup->{status} = "closed";
            }
        }

        $alertgroup->{updated}  = int($alertgroup->{updated});

        $log->trace("[Alertgroup $agid] New alertgroup == ", {filter=>\&Dumper, value=>$alertgroup});

        my $newalertgroup   = $meerkat->collection('Alertgroup')->exact_create($alertgroup);


        $log->debug("[Alergroup $agid] creating sources");
        create_targetable("source", $newalertgroup, @sources);
        $log->debug("[Alergroup $agid] creating tags");
        create_targetable("tag", $newalertgroup, @tags);

        my $alertcursor = $alerts->find({alertgroup => $alertgroup->{id}});
        $alertcursor->immortal(1);

        $log->debug("[Alertgroup $agid] has " . $alertcursor->count . " alerts");

        while ( my $alert = $alertcursor->next ) {

            my $id      = delete $alert->{alert_id};
            $log->debug("[Alertgroup $agid] [Alert $id] Begins processing");

            delete $alert->{idfield};
            delete $alert->{collection};
            my @history = @{delete $alert->{history}};
            my @events  = @{delete $alert->{events}};
            my @tags    = @{delete $alert->{tags}};
            $alert->{id} = $id;
            $alert->{updated} = int($alert->{updated});
            delete $alert->{data_with_flair};
            $alert->{parsed} = 0;
            
            foreach my $event (@events) {
                $alert->{promotions}->{to} = {
                    type    => "alert",
                    id      => $event,
                };
            }

            delete $alert->{searchtext};
            delete $alert->{entities};

            $log->debug("[Alertgroup $agid] [Alert $id] creating alert ");
            my $cmdlength = length(Dumper($alert));
            $log->debug("[Alertgroup $agid] [Alert $id] alert cmd length = $cmdlength");
            my $aobj    = $meerkat->collection('Alert')->exact_create($alert);

            $log->debug("[Alertgroup $agid] [Alert $id] creating alert flair");
            process_alert_flair($aobj);

            $log->debug("[Alertgroup $agid] [Alert $id] creating history");
            create_targetable("history", $aobj, @history);

            $log->debug("[Alertgroup $agid] [Alert $id] creating tags");
            create_targetable("tag", $aobj, @tags);

        }
    }
}

sub process_events {

    my $restart_id  = get_restart_id('Event');
    if ($restart_id == 0) {
        $restart_id = $doevents;
    }

    my $event_cursor = $events->find({event_id => {'$gte' => $restart_id}});
    $event_cursor->immortal(1);

    $log->debug("Processing ". $event_cursor->count . " events");

    while ( my $event = $event_cursor->next ) {

        my $eid = delete $event->{event_id};
        $log->debug("[Event $eid] Begins processing");

        delete $event->{idfield};
        delete $event->{collection};
        $event->{id}            = $eid;
        $event->{views}         = delete $event->{view_count};
        $event->{view_history}  = delete $event->{viewed_by};
        $event->{groups}   = {
            read    => delete $event->{readgroups},
            modify  => delete $event->{modifygroups},
        };
        my @sources = @{ delete $event->{sources} // []};
        my @tags    = @{ delete $event->{tags} // [] };
        my @history = @{ delete $event->{history} // []};

        $event->{promotions}   = { 
            to   => delete $event->{incidents},
            from => delete $event->{alerts}
        };

        $log->debug("[Event $eid] Creating Event");
        my $eobj    = $meerkat->collection('Event')->exact_create($event);
        $log->debug("[Event $eid] Creating History");
        create_targetable("history", $eobj, @history);
        $log->debug("[Event $eid] Creating Tags");
        create_targetable("tag", $eobj, @tags);
        $log->debug("[Event $eid] Creating Sources");
        create_targetable("source", $eobj, @sources);
    }
}

sub process_incidents {
    my $restart_id  = get_restart_id('Incident');
    if ($restart_id == 0) {
        $restart_id = $doincidents;
    }
    my $inc_cursor  = $incidents->find({ incident_id => { '$gte' => $restart_id}});
    $inc_cursor->immortal(1);

    $log->debug("Processing ". $inc_cursor->count. " incidents");

    while ( my $incident = $inc_cursor->next ) {

        my $iid = delete $incident->{incident_id};
        $log->debug("[Incident $iid] Begins Processing");

        $incident->{id}     = $iid;
        delete $incident->{idfield};
        delete $incident->{collection};
        my @history = @{ delete $incident->{history} // []};
        my @sources = @{ delete $incident->{sources} // []};
        my @tags    = @{ delete $incident->{tags} // [] };
        $incident->{promotions}   = { 
            from => delete $incident->{events}
        };
        $incident->{groups}   = {
            read    => delete $incident->{readgroups},
            modify  => delete $incident->{modifygroups},
        };
        $log->debug("[Incident $iid] Creating Incident");
        my $iobj    = $meerkat->collection('Incident')->exact_create($incident);
        $log->debug("[Incident $iid] Creating History");
        create_targetable("history", $iobj, @history);
        $log->debug("[Incident $iid] Creating Tags");
        create_targetable("tag", $iobj, @tags);
        $log->debug("[Incident $iid] Creating Sources");
        create_targetable("source", $iobj, @sources);
        
    }
}

sub process_entries {
    my $restart_id  = get_restart_id('Entry');
    if ($restart_id == 0) {
        $restart_id = $doentry;
    }
    my $ecursor = $entries->find({ entry_id => { '$gte' => $restart_id }});
    $ecursor->immortal(1);

    $log->debug("Processing ". $ecursor->count . " entries");

    print "GOT ".$ecursor->count." Entries to process\n";

    while ( my $entry = $ecursor->next ) {

        my $eid = delete $entry->{entry_id};
        $log->debug("[Entry $eid] Begins processing");

        $entry->{id}    = $eid;
        delete $entry->{idfield};
        delete $entry->{collection};

        # TODO: must put a check of summary somewhere

        $entry->{parent}    = $entry->{parent} // 0;
        delete $entry->{body_flaired};
        delete $entry->{body_plaintext};

        $entry->{groups}    = {
            read    => delete $entry->{readgroups},
            modify  => delete $entry->{modifygroups},
        };

        my @history = @{ delete $entry->{history} // [] };
        $entry->{parsed} = 0;
        $entry->{when} = int($entry->{when});

        my $targets = [ { type => $entry->{target_type}, id => $entry->{target_id} } ];
        $entry->{targets}   = $targets;
        delete $entry->{target_type};
        delete $entry->{target_id};
        
        $log->debug("[Entry $eid] creating entry");
        my $eobj    = $meerkat->collection('Entry')->exact_create($entry);

        unless ( $eobj ) {
            $log->error("[Entry $eid] FAILED to create object!");
            next;
        }

        $log->debug("[Entry $eid] flairing entry");
        process_entry_flair($eobj);

        $log->debug("[Entry $eid] creating history");
        create_targetable("history", $eobj, @history);

    }
}

sub create_targetable {
    my $type    = ucfirst(shift);
    my $target  = shift;

    my $col = $meerkat->collection($type);

    my @things  = @_;

    foreach my $thing (@things) {
        print "Creating targetable $type of ".Dumper($thing)."\n";
        if ( ref($thing) eq "ARRAY" ) {
            $thing = shift @$thing;
        }
        if ( $type eq "Source" or $type eq "Tag" ) {
            my $src_obj = $col->find_one({value => $thing});
            if ( $src_obj ) {
                $src_obj->update({
                    '$addToSet' => { 
                        targets => { 
                            target_type => $target->get_collection_name,
                            target_id   => $target->id,
                        }
                    }
                });
            }
            else {
                $col->create({
                    value    => $thing,
                    targets => [{
                        target_type => $target->get_collection_name,
                        target_id   => $target->id,
                    }],
                });
            }
        }
        elsif ( $type eq "History" ) {
            foreach my $item (@things) {
                next unless $item;
                my $history = {
                    who     => $item->{who},
                    what    => $item->{what}, 
                    when    => int($item->{when}),
                    targets => [{
                        target_type => $target->get_collection_name, target_id => $target->id
                    }],
                };
                # $log->trace("[$type] creation using ",{filter=>\&Dumper, value=>$history});
                $col->create($history);
            }
        }
        else {
            $log->debug("unrecognized type $type ");
        }
    }
}

sub process_alert_flair {
    my $alert   =   shift;
    my $data    = $alert->data;
    my @entities    = ();
    my %flair;
    my %seen;
    
    TUPLE:
    while ( my ( $key, $value ) = each %{$data} ) {

        my $encoded = '<html>' . encode_entities($value) . '</html>';
        if ( $key =~ /^message_id$/i ) {
            push @entities, { value => $value, type => "message_id" };
            next TUPLE;
        }
        my $href    = $extractor->process_html($encoded);

        $flair{$key}    = $href->{flair};

        foreach my $entityhref ( @{$href->{entities}} ) {
            my $v = $entityhref->{value};
            my $t = $entityhref->{type};
            unless ( defined $seen{$v} ) {
                push @entities, $entityhref;
                $seen{$v}++;
            }
        }
    }

    my $flairsize   = length(Dumper(\%flair));

    if ( $flairsize > 1000000 ) {
        $log->debug("[Alert ".$alert->id."] Really large flair command! $flairsize chars");
        $env->log->warn("[Alert ".$alert->id."] FLAIR cmd length is $flairsize");
        $env->log->warn("[Alert ".$alert->id."] skipping Alert: ");
        return;
    }
    

    $alert->update({
        '$set'  => {
            data_with_flair => \%flair,
            parsed          => 1,
        }
    });
    $meerkat->collection('Entity')->update_entities_from_target($alert, \@entities);
}

sub process_entry_flair {
    my $entry   = shift;
    unless ($entry) {
        $log->error("[Entry ??] Not defined! ");
        return;
    }
    my $data    = $entry->body;
    unless ($data) {
        $log->error("[Entry ".$entry->id."] BAD BODY!",{filter=>\&Dumper,value=>$entry->as_hash});
        return;
    }
    my $href    = $extractor->process_html($data);

    $entry->update({
        '$set'  => {
            parsed  => 1,
            body_plain  => $href->{text},
            body_flair  => $href->{flair},
        }
    });
    $meerkat->collection('Entity')->update_entities_from_target($entry, $href->{entities});
}

