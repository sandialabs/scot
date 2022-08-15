#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use MongoDB::Database;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file=>$config_file});
ok(defined $env, "Environment defined");
is(ref($env), "Scot::Env", "and its a Scot::Env");

require_ok('Scot::Flair::Worker');
my $worker = Scot::Flair::Worker->new({env => $env});
ok(defined $worker, "worker instantiated");
ok(ref($worker) eq "Scot::Flair::Worker", "its a Scot::Flair::Worker");

my $proc    = $worker->get_processor({data => { type => 'alertgroup' } });
my $proddb  = MongoDB->connect->db('scot-prod');
my $p_a_col= $proddb->get_collection('alert');
my $mongo   = $env->mongo;
my $acol    = $mongo->collection('Alert');

my $total_time = $env->get_timer("Total_Time");

my $do_this_id = $ARGV[0] + 0;

my $count   = 0;
my $limit   = 100;
my $prob    = 0.01;
my $total_a = $p_a_col->count_documents({});
my $total_flair_time = 0;

say "Total alerts = $total_a";

while ( $count++ < $limit ) {

    my $rando       = int(rand($total_a)) + 1;

    if ( $do_this_id > 0 ) {
        $rando = $do_this_id;
    }
    my $p_a_href    = $p_a_col->find_one({id => $rando});

    if ( ! defined $p_a_href ) {
        say "NULL Alert found: $rando";
        $count--;
        next;
    }

    say "Alert $rando ----------------";

    my $p_data          = $p_a_href->{data};
    my $p_data_flair    = $p_a_href->{data_with_flair};

    foreach my $key (keys %$p_data) {
        next if $key eq "columns" or $key eq "_raw";
        my $plain_aref          = $p_data->{$key};
        my $flaired_data          = $p_data_flair->{$key};
        my $expected_entities   = build_expected_edb($rando);
        my $flair_time          = $env->get_timer("flair_$rando");
        my $result              = $proc->flair_alert($p_a_href);
        my $elapsed = &$flair_time;
        $total_flair_time += $elapsed;

        # say "Results =======================";
        # say Dumper($result);
        # say "===============================";

        ok(compare_edb($result->{entities}, $expected_entities), "Alert $rando Key $key") or die;

        my $got_flair = $result->{data_with_flair}->{$key};
        $got_flair =~ s/[\h\v]+/ /g; # concat all spaces to single
        $got_flair =~ s/ </</g; # trim space before tag
        $got_flair =~ s/&nbsp;//g; # remove web spaces

        if ( ! defined $flaired_data ) {
            say "skipping key $key because does not exist in db to compare";
            next;
        }
        else {
            $flaired_data =~ s/[\h\v]+/ /g;
            $flaired_data =~ s/ </</g;
        }



        is(lc($got_flair), lc($flaired_data), "flair matches") or myfail($got_flair, $flaired_data);

        if ( $do_this_id > 0 ) {
            last;
        }
    }
}

say "Total Flair Time = ".$total_flair_time;
my $avg = $total_flair_time / $count;
say "AVG   Flair Time = ".$avg;
say "All test Time    = ". &$total_time;

done_testing();

sub compare_edb {
    my $g   = shift;
    my $e   = shift;

    foreach my $type(keys %$e) {
        foreach my $value (keys %{$e->{$type}} ) {
            if ( ! defined $g->{$type}->{$value} ) {
                print "Missing $type $value in parsed edb\n";
                print "Got: ".Dumper($g);
                print "Exp: ".Dumper($e);
                return undef;
            }
        }
    }
    return 1;
}



sub myfail {
    my $g = shift;
    my $e = shift;

    say "Got: -----x---------x---------x";
    say Dumper($g);
    say "Exp: -----x---------x---------x";
    say Dumper($e);
    if (! ref($g) and ! ref($e) ) {
        highlight_string_diff($g,$e);
    }
    say "\nContinue?....";
    my $input = <STDIN>;
}

sub highlight_string_diff {
    my $g   = shift;
    my $e   = shift;

    for (my $i = 0; $i < length($g); $i++) {
        my $gc = substr $g, $i, 1;
        my $ec = substr $e, $i, 1;

        if ( $gc ne $ec ) {
            print ">$gc<";
            return;
        }
        else {
            print "$gc";
        }
    }
}


sub build_expected_edb {
    my $id      = shift;
    my $vertex  = {
        id      => $id,
        type    => 'alert'
    };
    my $query   = {
        '$and'  => [
            { vertices => { '$elemMatch' => $vertex } },
            { 'vertices.type' => 'entity' },
        ],
    };
    my $cursor  = $proddb->get_collection('Link')->find($query);

    my %edb = ();

    while ( my $href = $cursor->next ) {

        my $value   = $href->{value};
        my $type    = $href->{type};

        $edb{$type}{$value} ++;
    }
    return \%edb;
}

