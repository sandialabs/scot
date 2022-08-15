#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::Util::MongoFactory;
use HTML::Entities;
use IO::Handle;
use Meerkat;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({ config_file => $config_file });

# print Dumper($env);
# print Dumper($prodenv);

system("/usr/bin/mongo scot-test ./reset.js");

 ok (defined $env, "Environment defined");
 is (ref($env), "Scot::Env", "and defined as a Scot::Env");

my $prodmongo = Meerkat->new(
    model_namespace     => 'Scot::Model',
    collection_namespace => 'Scot::Collection',
    database_name        => 'scot-prod',
    client_options       => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timout_ms => 600000,
    },
);
my $testmongo = $env->mongo;

my $test_prod_alert = $prodmongo->collection('Alert')->find_one({});
my $test_test_alert = $testmongo->collection('Alert')->find_one({});

ok(defined $test_prod_alert, "Found an alert in prod");
ok(! defined $test_test_alert, "Didnot find on in test");

require_ok('Scot::Flair::Worker');
my $worker  = Scot::Flair::Worker->new({env => $env});
ok (defined $worker, "Worker defined");
is (ref($worker), "Scot::Flair::Worker", "and defined as Scot::Flair::Worker");

my $skip     = int(rand(10)) * 100;
my $limit    = 10;

foreach my $proc_type (qw(entry alertgroup)) {
    # compare_entries()       if ( $proc_type eq "entry" );
    compare_alertgroups()   if ( $proc_type eq "alertgroup");
}

sub open_stat_file {
    my $filename    = shift;
    open my $fh, '>>', $filename or die "Can't open $filename: $!";
    $fh->autoflush(1);
    return $fh;
}

sub compare_entries {
    my $count       = 0;
    my $cursor      = get_cursor("entry");
    my $nextskip    = 0;
    my $processor   = $worker->get_processor({data => { type => 'entry' }});
    my $totaltime   = 0;
    my $fh          = open_stat_file("entry_timing.csv");

    print "Comparing Entries...\n";

    while (my $entry = $cursor->next) {
        if ( $nextskip != 0 ) {
            $nextskip--;
            next;
        }
        $nextskip = $skip;

        if (!defined $entry and ref($entry) ne "Scot::Model::Entry") {
            die "Failed to get Entry!";
        }

        if ( $count > $limit ) {
            last;
        }

        $count++;
        my $entry_id    = $entry->id;
        my $body        = $entry->body;
        my $exp_edb     = build_expected_edb($prodmongo, $entry);

        my $test_entry  = $testmongo->collection('Entry')->exact_create(
            $entry->as_hash
        );
        # must create target of entry too 
        my $target      = $test_entry->target;
        my $tcol        = ucfirst($target->{type});
        my $tid         = $target->{id} + 0;
        my $prod_target_obj = $prodmongo->collection($tcol)->find_iid($tid);
        my $test_target_obj = $testmongo->collection($tcol)->exact_create($prod_target_obj->as_hash);
        # now do what we are here for!
        my $flair_time  = $env->get_timer("Entry $entry_id");
        my $results     = $processor->flair_object($test_entry);
        my $elapsed     = &$flair_time;
        $totaltime      += $elapsed;

        my $max_recursion = $processor->extractor->max_level;
        $processor->extractor->max_level(0);
        my $entities_found = keys %{$results->{entities}};
        my $bodysize       = length($test_entry->body_flair);

        my $line = join(',', 'entry', $entry_id, $bodysize, $max_recursion, $entities_found, $elapsed)."\n";
        print $fh $line;

        ok(compare_edb("Entry $entry_id", $results->{entities}, $exp_edb), "Entry $entry_id EDB match");
    }
}

sub duplicate_alertgroup {
    my $ag  = shift;
    my $agid    = $ag->id;
    my $aghash  = $ag->as_hash;
    my $new_ag  = $testmongo->collection('Alertgroup')->exact_create($aghash);
    if (! defined $new_ag) {
        die "Failed to duplicate Alertgroup ".$agid;
    }
    my $query   = {alertgroup => $agid};
    my $cursor  = $prodmongo->collection('Alert')->find($query);
    my $count   = 0;
    while (my $alert = $cursor->next ) {
        my $alerthash = $alert->as_hash;
        my $newalert = $testmongo->collection('Alert')->exact_create($alerthash);
        if ( ! defined $newalert ) {
            die "Failed to create alert ".$alert->id;
        }
        $count++;
    }
    say "Duplicated $count alerts in alertgroup $agid";
    return $new_ag, $count;
}

sub compare_alertgroups {
    my $count       = 0;
    my $cursor      = get_cursor("alertgroup");
    my $nextskip    = 0;
    my $processor   = $worker->get_processor({data => { type => 'alertgroup' }});
    my $totaltime   = 0;
    my $fh          = open_stat_file("ag_timing.csv");

    while (my $item = $cursor->next) {
        if ( $nextskip != 0 ) {
            $nextskip--;
            next;
        }
        $nextskip = $skip;
        if ( $count > $limit ) {
            last;
        }
        $count++;

        my $item_id     = $item->id + 0;
        say "Alertgroup $item_id ------------";
        my $exp_edb     = build_expected_alertgroup_edb($prodmongo, $item);

        # say "Expecting: ".Dumper($exp_edb);

        my ($test_item, $acount)   = duplicate_alertgroup($item);

        my $flair_time  = $env->get_timer("Alertgroup $item_id");
        my $results     = $processor->flair_object($test_item);
        my $elapsed     = &$flair_time;
        $totaltime      += $elapsed;

        my $max_recursion = $processor->extractor->max_level;
        $processor->extractor->max_level(0);
        # say Dumper($results);
        my $entities_found = count_entities($results);

        # clear out extraneous

        ok(compare_ag_edb("Alertgroup $item_id", $results, $exp_edb), "Alertgroup $item_id EDB match");

        my $line = join(',', 'alertgroup', $item_id, $acount, $max_recursion, $entities_found, $elapsed)."\n";
        print $fh $line;
    }

}

sub count_entities {
    my $ag_edb  = shift;
    my $count   = 0;
    foreach my $aid (keys %$ag_edb) {
        $count += keys %{$ag_edb->{$aid}->{entities}};
    }
}


sub get_cursor {
    my $type = shift;

    my $query = { };
    my $count   = $prodmongo->collection(ucfirst($type))->count($query);
    print ucfirst($type).": Found $count items matching ".Dumper($query);
    my $cursor = $prodmongo->collection(ucfirst($type))->find($query);
    $cursor->sort({id => -1});
    return $cursor;
}

sub compare_edb {
    my $test   = shift;
    my $g   = shift;
    my $e   = shift;

    my %notseen = ();

    foreach my $t (keys %$g) {
        foreach my $v (keys %{$g->{$t}}) {
            $notseen{$t}{$v} = 1;
        }
    }

    foreach my $type (keys %$e) {
        foreach my $value (keys %{$e->{$type}} ) {
            delete $notseen{$type}{$value};
            if ( ! defined $g->{$type}->{$value} ) {
                my $error = "Failure on $test\nExpected Entity $value but not in results!\n".
                "Got: ".Dumper($g)."\n".
                "Exp: ".Dumper($e)."\n";
                $env->log->error($error);
                return undef;
            }
        }
    }

    foreach my $t (keys %notseen) {
        foreach my $v (keys %{$notseen{$t}}) {
            print "    additional entity found: $t -> $v\n";
        }
    }

    return 1;
}

sub compare_ag_edb {
    my $test    = shift;
    my $g       = shift;
    my $e       = shift;

    my %notseen = ();

    foreach my $aid (keys %{$g}) {
        foreach my $type (keys %{$g->{$aid}->{entities}}) {
            foreach my $value (keys %{$g->{$aid}->{entities}->{$type}}) {
                $notseen{$type}{$value} = 1;
            }
        }
    }

    my @missing_from_expected;

    foreach my $aid (keys %{$e}) {
        say "Looking at alert $aid";
        foreach my $type (keys %{$e->{$aid}->{entities}}) {
            say "  Looking at type $type";
            foreach my $value (keys %{$e->{$aid}->{entities}->{$type}}) {
                say "    Looking at value $value";
                delete $notseen{$type}{$value};
                if ( ! defined $g->{$aid}->{entities}->{$type}->{$value} ) {
                    say "      Not Defined!";
                    say "      g->{$aid}->{entities}->{$type}->{$value}";
                    my $error = "Failure on $test\nExpected Entity $value but not in results!\n";
                    # "Got: ".Dumper($g)."\n".
                    # "Exp: ".Dumper($e)."\n";
                    $env->log->error($error);
                    # return undef;
                    push @missing_from_expected, { type => $type, value => $value };
                }
            }
        }
    }
    my $ok = 1;
    say "--- Missing Entities ---";
    foreach my $miss (@missing_from_expected) {
        say $miss->{type}. '=>' . $miss->{value};
        $ok = undef;
    }

    foreach my $type (keys %notseen) {
        foreach my $value (keys %{$notseen{$type}}) {
            print "    additional entity found: $type -> $value\n";
        }
    }
    return $ok;
}

sub build_expected_edb {
    my $mongo   = shift;
    my $item    = shift;
    my $thing   = ref($item);
    my $id      = $item->id;
    my $subthing = "entity";

    my $type    = lc(( split(/::/,$thing) )[-1]);

    print "Building expected EDB for $thing $id $subthing\n";

    my $query = {
        '$and'  => [
            { vertices => { '$elemMatch' => { id      => $id, type    => $type, } }},
            { 'vertices.type' => 'entity' },
        ],
    };
    # say "Link query = ".Dumper($query);

    my $lcursor  = $mongo->collection('Link')->find($query);

    my @linkids = ();
    while (my $link = $lcursor->next) {
        my $verts = $link->vertices;
        my $target_id = ($verts->[0]->{type} eq $type and $verts->[0]->{id} == $id) ?
            $verts->[1]->{id} + 0 :
            $verts->[0]->{id} + 0 ;
        push @linkids, $target_id;
    }
    my $match = { id => { '$in' => \@linkids }};
    # print "Looking for ".Dumper($match);

    my $cursor  = $mongo->collection('Entity')->find($match);
    my %edb = ();
    while (my $object = $cursor->next) {

        my $type    = $object->type;
        my $value   = lc($object->value);

        # print "$type => $value expected\n";

        $edb{$type}{$value}++;
    }

    say "Expecting : ".Dumper(\%edb);
    return wantarray ? %edb : \%edb;
}

sub build_expected_alertgroup_edb {
    my $self    = shift;
    my $ag      = shift;
    my $agid    = $ag->id;
    my $alertcursor = $prodmongo->collection('Alert')->find({alertgroup => $agid});
    my %edb     = ();
    my $type    = 'alert';

    while ( my $alert = $alertcursor->next ) {
        my $alert_id    = $alert->id;
        my @links       = ();
        my $query = {
            '$and'  => [
                { vertices => { '$elemMatch' => { id      => $alert_id, type    => $type, } }},
                { 'vertices.type' => 'entity' },
            ],
        };
        my $lcursor  = $prodmongo->collection('Link')->find($query);
        my @linkids = ();
        while (my $link = $lcursor->next) {
            my $verts = $link->vertices;
            my $target_id = ($verts->[0]->{type} eq $type and $verts->[0]->{id} == $alert_id) ?
                $verts->[1]->{id} + 0 :
                $verts->[0]->{id} + 0 ;
            push @linkids, $target_id;
        }
        my $match = { id => { '$in' => \@linkids }};
        my $cursor  = $prodmongo->collection('Entity')->find($match);
        while (my $object = $cursor->next) {

            my $type    = $object->type;
            my $value   = lc($object->value);

            $edb{$alert_id}{entities}{$type}{$value}++;
        }
    }
    return wantarray ? %edb : \%edb;
}
