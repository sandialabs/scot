package Scot::Controller::Migrate;

use lib '../../../lib';

=head1 Name

Scot::Controller::Migrate

=head1 Description

This Controller will migrate a SCOT < 3.4 database
to a SCOT 3.5 database

=cut

use Scot::Env;
use Scot::Util::EntityExtractor;

use Data::Dumper;
use Try::Tiny;
use Parallel::ForkManager;
use HTML::Entities;
use Time::HiRes qw(gettimeofday tv_interval);
use MongoDB;
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

has legacy_client   => (
    is          => 'ro',
    isa         => 'MongoDB::MongoClient',
    required    => 1,
    builder     => '_build_legacy_client',
);

sub _build_legacy_client {
    my $self    = shift;
    my $client  = MongoDB::MongoClient->new();
    return $client;
}

has legacy_db   => (
    is          => 'ro',
    isa         => 'MongoDB::Database',
    required    => 1,
    lazy        => 1,
    builder     => '_get_legacy_db',
);

sub _get_legacy_db {
    my $self    = shift;
    my $client  = $self->legacy_client;
    return $client->db('scotng-prod');
}

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Util::EntityExtractor',
    required    => 1,
    lazy        => 1,
    builder     => '_get_entity_extractor',
);

has completed   => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

has total   => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

sub _get_entity_extractor {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $extractor   = Scot::Util::EntityExtractor->new({ log => $log });
    return $extractor;
}
sub get_pct {
    my $self            = shift;
    my $count           = $self->completed;
    my $legacy_count    = $self->total;
    my $pct = ( int( ($count/$legacy_count)*10000 )/100 );
    return $pct;
}

has child_count => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

sub commify {
    my $self    = shift;
    my $number  = shift;
    my $text    = reverse $number;
    $text       =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

has alerts_while_waiting    => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

has time_waiting    => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0
);

sub transform_alert {
    my $self    = shift;
    my $alert   = shift;
    my $log     = $self->env->log;
    my $id      = delete $alert->{id};

    $log->trace("[Alert $id] transforming alert");
    delete $alert->{idfield};
    delete $alert->{collection};
    delete $alert->{data_with_flair};
    delete $alert->{searchtext};
    delete $alert->{entities};

    my @history = @{ delete $alert->{history} };
    my @tags    = @{ delete $alert->{tags} };

    $alert->{id}        = $id;
    $alert->{updated}   = int($alert->{updated}); # in case a decimal
    $alert->{parsed}    = 0;

    my @events  = map {
        { type => "event", id => $_ }
    } @{ delete $alert->{events} // [] };

    $alert->{promotions}    = { to => \@events };

    # new format group permissions
    # will need to get this from alertgroups once they are migrated
    $alert->{groups}   = {
        read        => [],
        modify      => [],
    };
    return $alert, \@history, \@tags;
}

sub migrate_alerts_new {
    my $self    = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $startid = $self->get_latest_migrated_id('Alert');
    my $db      = $self->legacy_db;
    my $coll    = $db->get_collection('alerts');
    $self->completed($startid);

    my $cursor  = $coll->find({
        alert_id    => { '$gte' => $startid }
    });
    $cursor->immortal(1);

    my $legacy_count    = $cursor->count;
    $self->total($legacy_count);

    $log->debug("[Alert] Legacy DB has $legacy_count Alerts");
    my $count   = 0;
    my @requests;
    my %hist;
    my %tags;
    while ( my $alert = $cursor->next ) {
        my ($newalert, $history_aref, $tag_aref) = $self->transform_alert($alert);
        my $id = $newalert->{id};
        $count++;
        $hist{$id} = $history_aref;
        $tags{$id} = $tag_aref;
        push @requests, ( insert_one  => [ $newalert ] );
        
    }

}

sub migrate_alerts {
    my $self    = shift;
    my $fork    = shift // 0;
    my $log     = $self->env->log;
    my $meerkat = $self->env->mongo;
    my $startid = $self->get_latest_migrated_id('Alert');
    $self->completed($startid);
    my $db      = $self->legacy_db;
    my $coll    = $db->get_collection('alerts');

    $log->debug("====== Starting Alert Migration with alert_id = $startid =======");

    $log->debug("--- Forking Alert Migration requested: $fork children will be created ---");

    my $forkmgr    = Parallel::ForkManager->new($fork);
    $forkmgr    ->run_on_start( sub {
        my ($pid, $ident)   = @_;
        $log->trace("[$ident] Starting child process ");
        $self->child_count($self->child_count + 1);
    });
    $forkmgr    ->run_on_finish( sub {
        my ($pid, $exit, $ident) = @_;
        $log->trace("[$ident] Finished child process ");
        $self->completed($self->completed + 1);
        $self->child_count($self->child_count - 1);
        $self->alerts_while_waiting($self->alerts_while_waiting + 1);
    });
    $forkmgr    ->run_on_wait( sub {
        my $alerts_this_period = $self->alerts_while_waiting;
        $self->alerts_while_waiting(0);
        my $now                = time;
        my $time_waiting       = $now - $self->time_waiting;
        $self->time_waiting($now);
        $log->trace("---");
        $log->trace("--- waiting on ". $self->child_count . " children.");
        $log->trace("--- Total     ". sprintf("%15s",$self->commify($self->total)));
        $log->trace("--- completed ". sprintf("%15s",$self->commify($self->completed)) );
        $log->trace("--- Remain    ". sprintf("%15s",$self->commify( ($self->total - $self->completed) )));
        $log->trace("--- Pct. done ". $self->get_pct. "%");
        $log->trace("---");
        $log->trace("--- Alerts    ". sprintf("%15d",$alerts_this_period));
        $log->trace("--- Seconds   ". sprintf("%15d",$time_waiting));
        if ( $alerts_this_period > 0 and $time_waiting > 0) {
            my $rate    = ($alerts_this_period/$time_waiting);
            $log->trace("--- Rate      ". sprintf("%13.2f", $rate));
            if ( $rate > 0) {
                my $est     = (($self->total - $self->completed) / $rate)/3600;
                $log->trace("--- Est compl ". sprintf("%13.2f", $est));
            }
        }
    });

    my $cursor  = $coll->find({
        alert_id    => { '$gte' => $startid }
    });
    $cursor->immortal(1);

    my $legacy_count    = $cursor->count;
    $self->total($legacy_count);

    $log->debug("[Alert] Legacy DB has $legacy_count Alerts");
    my $count   = 0;

    while ( my $alert = $cursor->next ) {
        $count++;
        my $id  = delete $alert->{alert_id};
        my $pct = ( int( ($count/$legacy_count)*1000 )/10 );

        $log->debug("[Alert $id] $count of $legacy_count { $pct % }");

        $forkmgr->start("Alert $id") and next;

        # not needed in new object creation
        delete $alert->{idfield};
        delete $alert->{collection};
        delete $alert->{data_with_flair};
        delete $alert->{searchtext};
        delete $alert->{entities};

        my @history = @{ delete $alert->{history} };
        my @tags    = @{ delete $alert->{tags} };

        $alert->{id}        = $id;
        $alert->{updated}   = int($alert->{updated}); # in case a decimal
        $alert->{parsed}    = 0;

        my @events  = map {
            { type => "event", id => $_ }
        } @{ delete $alert->{events} // [] };

        $alert->{promotions}    = { to => \@events };

        # new format group permissions
        # will need to get this from alertgroups once they are migrated
        $alert->{groups}   = {
            read        => [],
            modify      => [],
        };

        my $object    = $meerkat->collection('Alert')->exact_create($alert);
        $meerkat->collection('Alert')->set_next_id($object->id);

        if ( $object and ref($object) eq "Scot::Model::Alert" ) {
            $log->debug("[Alert $id] Migrated to new database");
        }
        else {
            $log->error("[Alert $id] FAILED Migration!");
            $log->error("[Alert $id] Alert dump:",{filter=>\&Dumper, value=>$alert});
            next;
        }

        $self->do_alert_targetables($object, \@history, \@tags);
        
        # $self->process_alert_flair($object);

        # $self->create_targetable("history", $object, @history);

        # $self->create_targetable("tag", $object, @tags);

        $forkmgr->finish(0);
    }

    $forkmgr->wait_all_children;
    $log->debug("==== Finished Alerts ===");
}

sub do_alert_targetables {
    my $self    = shift;
    my $alert   = shift;
    my $history = shift;
    my $tags    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $alert->id;

    my $f   = Parallel::ForkManager->new(0);

    $f->run_on_start(sub {
        my ($pid, $ident) = @_;
        $log->trace("[Alert ".$alert->id."] Subprocess $ident start...");
    });

    $f->run_on_finish(sub {
        my ($pid, $exit, $ident) = @_;
        $log->trace("[Alert ".$alert->id."] Subprocess $ident finished...");
    });

    $f->run_on_wait(sub {
        $log->trace("[Alert ".$alert->id."] awaiting subprocesses");
    });

    foreach my $method (qw(flair history tags)) {
        if ( $method eq "flair" ) {
            $f->start($method) and next;
            $log->debug("[Alert $id] Processing Flair");
            $self->process_alert_flair($alert);
            $f->finish(0);
        }
        if ( $method eq "history" ) {
            $f->start($method) and next;
            $log->debug("[Alert $id] creating history");
            $self->create_targetable("history", $alert, @{$history});
            $f->finish(0);
        }
        if ( $method eq "tags" ) {
            $f->start($method) and next;
            $log->debug("[Alert $id] creating tags");
            $self->create_targetable("tag", $alert, @{$tags});
            $f->finish(0);
        }
    }
}


sub migrate_alertgroups {
    my $self    = shift;
    my $log     = $self->env->log;
    my $meerkat = $self->env->mongo;
    my $startid = $self->get_latest_migrated_id('Alertgroup');
    my $db      = $self->legacy_db;
    my $coll    = $db->get_collection('alertgroups');

    $log->debug("[[[[[[[[[[ Starting Alertgroup Migration with alergroup_id = $startid ]]]]]]]]]]");

    my $cursor  = $coll->find({
        alertgroup_id   => { '$gte' => $startid }
    });
    $cursor->immortal(1);

    my $legacy_count    = $cursor->count;

    $log->debug("[Alertgroup] Legacy DB has $legacy_count alertgroups");
    my $count = 0;

    while ( my $alertgroup = $cursor->next ) {
        $count++;
        my $id  = delete $alertgroup->{alertgroup_id};

        my $pct = (int(($count / $legacy_count)*1000))/10;
        $log->debug("[Alertgroup $id] $count of $legacy_count { $pct % }");

        delete $alertgroup->{idfield};      # not needed
        delete $alertgroup->{collection};   # not needed
        delete $alertgroup->{closed};       # not needed

        $alertgroup->{id}           = $id;
        $alertgroup->{body}         = delete $alertgroup->{body_html};
        $alertgroup->{views}        = delete $alertgroup->{view_count};
        $alertgroup->{view_history} = delete $alertgroup->{viewed_by};

        unless ($alertgroup->{body}) {
            $alertgroup->{body} = ' ';  # new scot requires a non zero body
        }

        # new format group permissions
        $alertgroup->{groups}   = {
            read        => delete $alertgroup->{readgroups},
            modify      => delete $alertgroup->{modifygroups},
        };

        my @sources = @{ delete $alertgroup->{sources} // [] };
        my @tags    = @{ delete $alertgroup->{tags} // [] };

        my @promotions = map { { type => "event", id => $_ } }
                            @{ delete $alertgroup->{events} // []};

        $alertgroup->{promotions}       = { to => \@promotions };
        $alertgroup->{total}            = delete $alertgroup->{alert_count} // 0;        
        $alertgroup->{open_count}       = delete $alertgroup->{open} // 0;        
        $alertgroup->{closed_count}     = delete $alertgroup->{closed} // 0;        
        $alertgroup->{promoted_count}   = delete $alertgroup->{promoted} // 0;        

        if ( $alertgroup->{status} =~ /\// ) {
            if ( $alertgroup->{promoted_count} > 0 ) {
                $alertgroup->{status}   = "promoted";
            }
            elsif ( $alertgroup->{open_count} > 0 ) {
                $alertgroup->{status}   = "open";
            }
            else {
                $alertgroup->{status}   = "closed";
            }
        }
        if ( $alertgroup->{status} eq "revisit" ) {
            $alertgroup->{status} = "closed";
        }

        $alertgroup->{updated}  = int($alertgroup->{updated}); # sometimes theres a decimal!

        my $object    = $meerkat->collection('Alertgroup')->exact_create($alertgroup);
        $meerkat->collection('Alertgroup')->set_next_id($object->id);

        if ( $object and ref($object) eq "Scot::Model::Alertgroup" ) {
            $log->debug("[Alertgroup $id] Migrated to new database");
        }
        else {
            $log->error("[Alertgroup $id] FAILED Migration!");
            $log->error("[Alertgroup $id] Alertgroup dump:",{filter=>\&Dumper, value=>$alertgroup});
            next;
        }

        $log->debug("[Alertgroup $id] creating sources");
        $self->create_targetable("source", $object, @sources);

        $log->debug("[Alertgroup $id] creating tags");
        $self->create_targetable("tag", $object, @tags);

    }

    $log->debug("[[[[[[[[[[ Finished Alertgroup Migration  ]]]]]]]]]]");

}

sub migrate_events {
    my $self    = shift;
    my $log     = $self->env->log;
    my $meerkat = $self->env->mongo;
    my $startid = $self->get_latest_migrated_id('Event');
    my $db      = $self->legacy_db;
    my $coll    = $db->get_collection('events');

    $log->debug("==== Starting Event Migration with event_id = $startid ====");

    my $cursor  = $coll->find({
        event_id   => { '$gte' => $startid }
    });
    $cursor->immortal(1);

    my $legacy_count    = $cursor->count;

    $log->debug("[Event] Legacy DB has $legacy_count events");
    my $count = 0;

    while ( my $event = $cursor->next ) {
        $count++;
        my $id  = delete $event->{event_id};
        $event->{id} = $id;

        my $pct = (int(($count / $legacy_count)*1000))/10;
        $log->debug("[Event $id] $count of $legacy_count { $pct % }");

        delete $event->{idfield};      # not needed
        delete $event->{collection};   # not needed
        
        $event->{views}         = delete $event->{view_count};
        $event->{view_history}  = delete $event->{viewed_by};
        $event->{groups}        = {
            read    => delete $event->{readgroups},
            modify  => delete $event->{modifygroups},
        };

        my @sources = @{ delete $event->{sources} // [] };
        my @tags    = @{ delete $event->{tags}    // [] };
        my @history = @{ delete $event->{history} // [] };

        $event->{promotions}    = {
            to      => delete $event->{incidents},
            from    => delete $event->{alerts},
        };

        $log->debug("[Event $id] Creating migrated object");
        my $object  = $meerkat->collection('Event')->exact_create($event);
        $meerkat->collection('Event')->set_next_id($object->id);

        if ( $object and ref($object) eq "Scot::Model::Event" ) {
            $log->debug("[Event $id] Migrated to new database");
        }
        else {
            $log->error("[Event $id] FAILED Migration!");
            $log->error("[Event $id] Event dump:",{filter=>\&Dumper, value=>$event});
            next;
        }

        $log->debug("[Event $id] creating history");
        $self->create_targetable("history", $object, @history);

        $log->debug("[Event $id] creating Tags");
        $self->create_targetable("tag", $object, @tags);

        $log->debug("[Event $id] creating Sources");
        $self->create_targetable("source", $object, @sources);
    }
    $log->debug("===== Finished Event processing =====");
}

sub migrate_incidents {
    my $self    = shift;
    my $log     = $self->env->log;
    my $meerkat = $self->env->mongo;
    my $startid = $self->get_latest_migrated_id('Incident');
    my $db      = $self->legacy_db;
    my $coll    = $db->get_collection('incidents');

    $log->debug("==== Starting Incident Migration with incident_id = $startid ====");

    my $cursor  = $coll->find({
        incident_id   => { '$gte' => $startid }
    });
    $cursor->immortal(1);

    my $legacy_count    = $cursor->count;

    $log->debug("[Incident] Legacy DB has $legacy_count incidents");
    my $count = 0;

    while ( my $incident = $cursor->next ) {
        $count++;
        my $id  = delete $incident->{incident_id};
        $incident->{id} = $id;

        my $pct = (int(($count / $legacy_count)*1000))/10;
        $log->debug("[Incident $id] $count of $legacy_count { $pct % }");

        delete $incident->{idfield};
        delete $incident->{collection};

        my @history = @{ delete $incident->{history} // []};
        my @sources = @{ delete $incident->{sources} // []};
        my @tags    = @{ delete $incident->{tags}    // []};

        $incident->{promotions} = { from => delete $incident->{events} };
        $incident->{groups}     = {
            read    => delete $incident->{readgroups},
            modify  => delete $incident->{modifygroups},
        };

        unless (defined $incident->{owner} ) {
            $incident->{owner} = "unknown";
        }

        $log->debug("[Incident $id] Creating migrated object");
        my $object  = $meerkat->collection('Incident')->exact_create($incident);
        $meerkat->collection('Incident')->set_next_id($object->id);

        if ( $object and ref($object) eq "Scot::Model::Incident" ) {
            $log->debug("[Incident $id] Migrated to new database");
        }
        else {
            $log->error("[Incident $id] FAILED Migration!");
            $log->error("[Incident $id] Event dump:",{filter=>\&Dumper, value=>$incident});
            next;
        }

        $log->debug("[Incident $id] creating history");
        $self->create_targetable("history", $object, @history);

        $log->debug("[Incident $id] creating Tags");
        $self->create_targetable("tag", $object, @tags);

        $log->debug("[Incident $id] creating Sources");
        $self->create_targetable("source", $object, @sources);
    }
}

sub migrate_entries {
    my $self    = shift;
    my $log     = $self->env->log;
    my $meerkat = $self->env->mongo;
    my $startid = $self->get_latest_migrated_id('Entry');
    my $db      = $self->legacy_db;
    my $coll    = $db->get_collection('entries');

    $log->debug("==== Starting Entry Migration with entry_id = $startid ====");

    my $cursor  = $coll->find({
        entry_id   => { '$gte' => $startid }
    });
    $cursor->immortal(1);

    my $legacy_count    = $cursor->count;

    $log->debug("[Entry] Legacy DB has $legacy_count events");
    my $count = 0;

    while ( my $entry = $cursor->next ) {
        my $bodylength = length $entry->{body};
        $log->debug("[Entry ".$entry->{entry_id}."] Body Length is $bodylength");
        if ( length($entry->{body}) > 2000000) {
            $log->warn("[Entry ".$entry->{entry_id}."] BODY IS HUGE! Saving for later splitting.");
            open my $out, '>>', "/tmp/huge.entries.txt";
            print $out $entry->{entry_id}."\n";
            close $out;
            next;
        }
        $count++;
        my $id  = delete $entry->{entry_id};
        $entry->{id} = $id;

        my $pct = (int(($count / $legacy_count)*1000))/10;
        $log->debug("[Entry $id] $count of $legacy_count { $pct % }");

        delete $entry->{idfield};
        delete $entry->{collection};
        delete $entry->{body_flaired};
        delete $entry->{body_plaintext};

        my @history = @{ delete $entry->{history} // [] };

        $entry->{parent}    = $entry->{parent} // 0;
        $entry->{groups}    = {
            read    => delete $entry->{readgroups},
            modify  => delete $entry->{modifygroups},
        };
        $entry->{parsed}    = 0;
        $entry->{when}      = int($entry->{when});
        $entry->{targets}   = [
            {
                type    => delete $entry->{target_type},
                id      => delete $entry->{target_id},
            }
        ];

        $log->debug("[Entry $id] Creating migration object");
        my $object  = $meerkat->collection("Entry")->exact_create($entry);
        next unless ($object);
        $meerkat->collection('Entry')->set_next_id($object->id);

        if ( $object and ref($object) eq "Scot::Model::Entry" ) {
            $log->debug("[Entry $id] Migrated to new database");
        }
        else {
            $log->error("[Entry $id] FAILED Migration!");
            $log->error("[Entry $id] Entry dump:",{filter=>\&Dumper, value=>$entry});
            next;
        }

        $log->debug("[Entry $id] Flairing entry");
        $self->process_entry_flair($object);

        $log->debug("[Entry $id] creating history");
        $self->create_targetable("history", $object, @history);
    }
    $log->debug("==== Entry processing done ====");
}

sub process_entry_flair {
    my $self    = shift;
    my $entry   = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $meerkat = $env->mongo;
    my $extractor   = $self->extractor;

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
            parsed      => 1,
            body_plain  => $href->{text},
            body_flair  => $href->{flair},
        }
    });
    $meerkat->collection('Entity')->update_entities_from_target($entry, $href->{entities});
    
}

sub get_latest_migrated_id {
    my $self    = shift;
    my $colname = shift;
    my $env     = $self->env;
    my $meerkat = $env->mongo;

    my $cursor  = $meerkat->collection($colname)->find({});
       $cursor->sort({id => -1});
    my $obj     = $cursor->next;
    if ( $obj ) {
        return $obj->id;
    }
    return 0;
}

sub create_targetable {
    my $self    = shift; 
    my $type    = ucfirst(shift);
    my $target  = shift;
    my $env     = $self->env;
    my $meerkat = $env->mongo;
    my $log     = $env->log;

    my $col = $meerkat->collection($type);

    my @things  = @_;

    foreach my $thing (@things) {
        # print "Creating targetable $type of ".Dumper($thing)."\n";
        if ( ref($thing) eq "ARRAY" ) {
            $thing = shift @$thing;
        }
        if ( $type eq "Source" or $type eq "Tag" ) {
            my $src_obj = $col->find_one({value => $thing});
            if ( $src_obj ) {
                $src_obj->update({
                    '$addToSet' => { 
                        targets => { 
                            type => $target->get_collection_name,
                            id   => $target->id,
                        }
                    }
                });
            }
            else {
                $col->create({
                    value    => $thing,
                    targets => [{
                        type => $target->get_collection_name,
                        id   => $target->id,
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
                        type => $target->get_collection_name, id => $target->id
                    }],
                };
                # $log->debug("[$type] creation using ",{filter=>\&Dumper, value=>$history});
                $col->create($history);
            }
        }
        else {
            $log->debug("unrecognized type $type ");
        }
    }

}

sub process_alert_flair {
    my $self    = shift;
    my $alert   = shift;
    my $data    = $alert->data;
    my $env     = $self->env;
    my $log     = $env->log;
    my $meerkat = $env->mongo;
    my $extractor   = $self->extractor;

    my @entities = ();
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

1;
