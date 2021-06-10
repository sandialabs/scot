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
        next if $key eq "columns";
        my $plain_aref          = $p_data->{$key};
        my $flaired_data          = $p_data_flair->{$key};
        my $expected_entities   = build_expected_entities($rando);
        my $expected_bag        = bag($expected_entities);
        my $flair_time          = $env->get_timer("flair_$rando");
        my $result              = $proc->flair_alert($p_a_href);
        my $elapsed = &$flair_time;
        $total_flair_time += $elapsed;

        # say "Results =======================";
        # say Dumper($result);
        # say "===============================";

        cmp_deeply($result->{entities}, supersetof(@$expected_entities), "EDB matches alert $rando key $key") or myfail($result->{entities}, $expected_entities);

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



        is($got_flair, $flaired_data, "flair matches") or myfail($got_flair, $flaired_data);

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

sub myfail {
    my $g = shift;
    my $e = shift;

    say "Got: -----x---------x---------x";
    say Dumper($g);
    say "Exp: -----x---------x---------x";
    say Dumper($e);
    say "\nContinue?....";
    my $input = <STDIN>;
}

sub build_expected_entities {
    my $id  = shift;
    my $req = {
        collection  => 'Alert',
        id          => $id,
        subthing    => 'entity',
    };

    my $cursor  = $mongo->collection('Alert')->api_subthing($req);
    my @e       = ();

    while ( my $entity = $cursor->next ) {
        my $type    = $entity->type;
        my $value   = $entity->value;
        if ( defined $type and defined $value ) {
            push @e, {
                type    => $type,
                value   => $value,
            };
        }
    }
    return \@e;
}


