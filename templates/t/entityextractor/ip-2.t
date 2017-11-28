#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';


use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';
my $config_file = $ENV{'scot_config_file'};
my $env = Scot::Env->new({
    config_file => $config_file
});
my $log = $env->log;
my $extractor   = $env->extractor;

my $source      = <<'EOF';
<html>Lets make sure that the router at <em>192</em>.<em>168</em>.<em>0</em>.<em>1</em> is still working</html>
EOF

my $flair   = <<'EOF';
<div>Lets make sure that the router at <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="192.168.0.1">192.168.0.1</span> is still working </div>
EOF

chomp($flair);

my $plain = <<'EOF';
Lets make sure that the router at 192.168.0.1 is still working
EOF

chomp($plain);

my $result  = $extractor->process_html($source);
print Dumper($result);

my @entities = (
    { 'value' => '192.168.0.1', 'type' => 'ipaddr' }
);

ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

$source = "<html>Test with ip ending a sentance 10.10.1.3. Next sentance</html>";
$flair = <<'EOF';
<div>Test with ip ending a sentance <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.1.3">10.10.1.3</span>. Next sentance </div>
EOF

chomp($flair);

$plain  = <<'EOF';
Test with ip ending a sentance 10.10.1.3. Next sentance
EOF

@entities = ( 
    {   'value' => '10.10.1.3', type => 'ipaddr' }
);

$result = $extractor->process_html($source);
ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
cmp_bag(\@entities, $result->{entities}, "entities correct");
is($result->{flair}, $flair, "Flair correct");

$source = "<html>Test with ip ending a sentance 10.10.1.3.a Next sentance</html>";
$flair = <<'EOF';
<div>Test with ip ending a sentance 10.10.1.3.a Next sentance </div>
EOF

chomp($flair);

$plain  = <<'EOF';
Test with ip ending a sentance 10.10.1.3.a Next sentance
EOF

@entities = ( 
);

$result = $extractor->process_html($source);
print Dumper($result),"\n";
ok(defined($result), "We have a result");
is(ref($result), "HASH", "and its a hash");
my $gotentities = $result->{entities};
ok(! defined ($gotentities), "entities correct");
is($result->{flair}, $flair, "Flair correct");

done_testing();
exit 0;

