#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);


my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
ok(defined $env, "Environment defined");
is(ref($env), "Scot::Env", "it is a Scot::Env");

require_ok('Scot::Flair::Worker');
my $worker = Scot::Flair::Worker->new({env => $env});
ok(defined $worker, "Worker module instantiated");
ok(ref($worker) eq 'Scot::Flair::Worker', 'got what we expected');

my $edata   = {
    class   => 'entry',
    metadata=> {},
    parent  => 0,
    body    => qq{The quick brown fox google.com the ipaddr of 10.10.10.1},
    parser  => 0,
    groups  => {
        read    => [ 'wg-scot-ir' ],
        modify  => [ 'wg-scot-ir' ],
    },
    owner   => 'scot-test',
    target  => { type => 'event', id => 100 },
    tlp     => 'amber',
};
my $mongo   = $env->mongo;
my $col     = $mongo->collection('Entry');
my $entry   = $col->create($edata);

my $message     = {
    action  => 'created',
    data    => { type => 'entry', id => $entry->id },
};
my $processor   = $worker->get_processor($message);
my $results     = $processor->flair_object($entry);

my $expect = {
	'entities' => [
		{
		'type' => 'domain',
		'value' => 'google.com'
		},
		{
		'type' => 'ipaddr',
		'value' => '10.10.10.1'
		}
    ],
	'text' => 'The quick brown fox google.com the ipaddr of 10.10.10.1
',
	'flair' => '<div>The quick brown fox <span class="entity domain" data-entity-type="domain" data-entity-value="google.com">google.com</span> the ipaddr of <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span></div>'
};

cmp_deeply ($results, $expect, "Flaired correctly");

is ($entry->body_flair, $expect->{flair}, "Entry flair was updated");
is ($entry->body_plain, $expect->{text}, "Entry plaintext was updated");

$env->log->debug("results: ",{filter=>\&Dumper, value=>$results});
done_testing();
