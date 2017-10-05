#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Safe;

$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';
my $config_file = $ENV{'scot_config_file'};
my $env = Scot::Env->new({
    config_file => $config_file
});
my $log         = $env->log;
my $extractor   = $env->extractor;

my $container   = new Safe 'Examples';
my $loadresult  = $container->rdo("./examples.pl");
my $hashname    = 'Examples::examples';
my %copy        = %$hashname;
my $href        = \%copy;

foreach my $series (sort keys %$href) {
    print "=== Test Series $series ====\n";
    my $shref   = $href->{$series};
    foreach my $test (keys %$shref) {

        print "---- Test: $test ----\n";

        my $expected    = $shref->{$test};
        my $debug       = $expected->{debug};
        my $entities    = $expected->{entities};
        my $flair       = $expected->{flair};
        chomp($flair);
        my $plain       = $expected->{plain};
        chomp($plain);
        my $source      = $expected->{source};
        my $result      = $extractor->process_html($source);

#    print Dumper($result)."\n";

        ok(defined($result),   "Extractor generated a result");
        is(ref($result),       "HASH", "and its a hash");

        my $r_entities  = $result->{entities};

        if ( scalar(@$entities) == 0 ) {
            ok (! defined($r_entities), "no entities ok");
        }
        else {
            cmp_bag($entities, $result->{entities}, "entities correct");
        }

        my $rplain = $result->{text};
        chomp($rplain);
        if (defined $debug) {
            print "Expected Plain :\n".$plain.":\n";
            print "Result   Plain :\n".$rplain.":\n";
        }
        my @rplain_lines = split(/\n/,$rplain);
        my @plain_lines  = split(/\n/,$plain);

        for (my $i = 0; $i < scalar(@rplain_lines); $i++) {
            my $c_rplain = $rplain[$i];
            chomp($c_rplain);
            my $c_plain = $plain[$i];
            chomp($c_plain);
            is($c_rplain, $c_plain, "Plain line $i is correct");
        }

        my $rflair = $result->{flair};
        chomp($rflair);
        if (defined $debug) {
            print "Expected Flair :\n".$flair.":\n";
            print "Result   Flair :\n".$rflair.":\n";
        }
        is($rflair, $flair, "Flair correct");

    }
}

done_testing();
exit 0;

