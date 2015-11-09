#!/usr/bin/env perl

use lib '../lib';
use Data::Dumper;
use Scot::Env;
use Scot::Util::EntityExtractor;
use HTML::Entities;
use MongoDB;
use Getopt::Long qw(GetOptions);
use v5.18;

$ENV{scot_mode} = "test";
my $env     = Scot::Env->new();
my $meerkat = $env->mongo;
my $log     = $env->log;
my $extractor   = Scot::Util::EntityExtractor->new({ log => $log });

my $doalerts    = 1;
my $doevents    = 1;
my $doincidents = 1;
my $doentry     = 1;

GetOptions( 
    "alert=i"    => \$doalerts,
    "event=i"    => \$doevents,
    "incident=i" => \$doincidents,
    "entry=i"     => \$doentry,
) or die <<EOF;

    INVALID OPTION

    useage: $0 
        --alert=x   start at alertgroup id of x, 0 skip all alertgroups
        --event=x   start at event id of x, 0 skip all
        --incident=x
        --entry=x

EOF


my $client  = MongoDB::MongoClient->new();

my $db  = $client->get_database("scotng-prod");

my $alertgroups  = $db->get_collection('alertgroups');
my $alerts      = $db->get_collection('alerts');

my $agcursor    = $alertgroups->find({id    => { '$gte' => $doalerts }});

while ( my $alertgroup = $agcursor->next ) {

    say "Alertgroup ". $alertgroup->{alertgroup_id};

    delete $alertgroup->{idfield};
    delete $alertgroup->{collection};
    $alertgroup->{id}           = delete $alertgroup->{alertgroup_id};
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

    $alertgroup->{updated}  = int($alertgroup->{updated});

    $log->trace("new alertgroup == ", {filter=>\&Dumper, value=>$alertgroup});

    my $newalertgroup   = $meerkat->collection('Alertgroup')->exact_create($alertgroup);


    say "   creating sources";
    create_targetable("source", $newalertgroup, @sources);
    say "   creating tags";
    create_targetable("tag", $newalertgroup, @tags);

    my $alertcursor = $alerts->find({alertgroup => $alertgroup->{id}});

    say "   has " . $alertcursor->count . " alerts";

    while ( my $alert = $alertcursor->next ) {

        delete $alert->{idfield};
        delete $alert->{collection};
        my @history = @{delete $alert->{history}};
        my @events  = @{delete $alert->{events}};
        my @tags    = @{delete $alert->{tags}};
        my $id      = delete $alert->{alert_id};
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

        say "       creating alert";
        my $aobj    = $meerkat->collection('Alert')->exact_create($alert);

        say "       creating alert flair";
        process_alert_flair($aobj);

        say "           creating history";
        create_targetable("history", $aobj, @history);

        say "           creating tags";
        create_targetable("tag", $aobj, @tags);

    }
#    print "press enter to continue...";
#    my $foo = <STDIN>;
}

my $events      = $db->get_collection('events');
my $event_cursor = $events->find();

while ( my $event = $event_cursor->next ) {

    say "Event $event->{event_id}";

    delete $event->{idfield};
    delete $event->{collection};
    $event->{id}            = delete $event->{event_id};
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

    say "   Creating Event";
    my $eobj    = $meerkat->collection('Event')->exact_create($meerkat);
    say "   Creating History";
    create_targetable("history", $eobj, @history);
    say "   Creating Tags";
    create_targetable("tag", $eobj, @tags);
    say "   Creating Sources";
    create_targetable("source", $eobj, @sources);
}

my $incidents   = $db->get_collection('incidents');
my $inc_cursor  = $incidents->find();

while ( my $incident = $inc_cursor->next ) {

    say "Incident $incident->{incident_id}";

    $incident->{id}     = delete $incident->{incident_id};
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
    say "   Creating Incident";
    my $iobj    = $meerkat->collection('Incident')->exact_create($incident);
    say "   Creating History";
    create_targetable("history", $iobj, @history);
    say "   Creating Tags";
    create_targetable("tag", $iobj, @tags);
    say "   Creating Sources";
    create_targetable("source", $iobj, @sources);
    
}

my $entries = $db->get_collection('Entries');
my $ecursor = $entries->find();

while ( my $entry = $ecursor->next ) {

    say "Entry $entry->{entry_id}";

    $entry->{id}    = delete $entry->{entry_id};
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
    
    say "   creating entry";
    my $eobj    = $meerkat->collection('Entry')->exact_create($entry);

    say "   flairing entry";
    process_entry_flair($eobj);

    say "   creating history";
    create_targetable("history", $eobj, @history);

}

sub create_targetable {
    my $type    = ucfirst(shift);
    my $target  = shift;

    my $col = $meerkat->collection($type);

    my @things  = @_;

    foreach my $thing (@things) {
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
                $col->create({
                    who     => $item->{who} ,
                    what    => $item->{what} , 
                    when    => int($item->{when}),
                    targets => [{
                        target_type => $target->get_collection_name,target_id => $target->id
                    }],
                });
            }
        }
        else {
            say "unrecognized type $type ";
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
    my $data    = $entry->body;
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

