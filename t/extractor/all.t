#!/usr/bin/env perl
use v5.18;
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Safe;

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

$ENV{'scot_config_file'}    = './extractor.cfg.pl';
my $config_file = $ENV{'scot_config_file'};
my $env = Scot::Env->new({
    config_file => $config_file
});

my $mongo   = $env->mongo;
my $etcol   = $mongo->collection('Entitytype');
my @ets     = map { $etcol->create($_); } ( 
    { value => "userdef-1", match => "Testing Foo", options => { multiword => "yes" } },
    { value => "userdef-2", match => "Zoo Kachoo", options => { multiword => "yes" } },
    { value => "jrock1",    match => "bcdedit /set", options => { multiword => "yes" } },
);

$env->regex->load_entitytypes();

my $log         = $env->log;
my $extractor   = $env->extractor;
my $etcur       = $etcol->find({});

is ($etcur->count, 2, "Found correct number of entitytypes");

while ( my $et = $etcur->next ) {
    say ref($et);
    say $et->value . " matches " . $et->match;
}



no strict 'refs';
my $container   = new Safe 'Examples';
# my $loadresult  = $container->rdo("./examples.pl");
my $loadresult  = $container->rdo("./examples.pl");
my $arrayname   = 'Examples::data';
my @copy        = @$arrayname;
my $aref        = \@copy;
use strict 'refs';

foreach my $test (sort { $a->{testnumber} <=> $b->{testnumber} } @$aref) {

    print "=== Test number $test->{testnumber} ====\n";
    print "=== $test->{testname} : $test->{testgroup}\n";

    my $errorcount  = 0;
    my $debug       = $test->{debug};
    my $entities    = $test->{entities};
    my $userdef     = $test->{userdef} // [];
    my $flair       = $test->{flair}; chomp($flair);
    my $plain       = $test->{plain}; chomp($plain);
    my $source      = $test->{source};
    print "--Source-------\n";
    print $source."\n";
    print "---Result------\n";
    my $result      = $extractor->process_html($source);
    print Dumper($result)."\n";

    ok(defined($result),   "Extractor generated a result") or $errorcount++;
    is(ref($result),       "HASH", "and its a hash") or $errorcount++;

    my $r_entities  = $result->{entities};
    my $r_userdef   = $result->{userdef};

    if ( scalar(@$entities) == 0 ) {
        ok (! defined($r_entities), "no entities ok") or $errorcount++;
    }
    else {
        cmp_bag($entities, $result->{entities}, "entities correct") or $errorcount++;
    }

    if ( scalar(@$userdef) == 0 ) {
        ok (! defined($r_userdef), "no userdef ok" ) or $errorcount++;
    }
    else {
        cmp_bag($userdef, $r_userdef, "user defined entities correct") or $errorcount++;
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
        my $c_rplain = $rplain_lines[$i];
        chomp($c_rplain);
        my $c_plain = $plain_lines[$i];
        chomp($c_plain);
        is($c_rplain, $c_plain, "Plain line $i is correct") or $errorcount++;
    }

    my $rflair = $result->{flair};
    chomp($rflair);
    if (defined $debug) {
        print "Expected Flair :\n".$flair.":\n";
        print "Result   Flair :\n".$rflair.":\n";
    }
    is($rflair, $flair, "Flair correct") or $errorcount++;

    if ($errorcount > 0) {
        die "Errors!\n";
    }
}

done_testing();
exit 0;

