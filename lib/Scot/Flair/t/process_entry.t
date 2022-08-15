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

my $event = create_event();

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
    target  => { type => 'event', id => $event->id },
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
	'entities' => {
		'ipaddr' => { '10.10.10.1' => 1 },
		'domain' => { 'google.com' => 1 },
    },
	'text' => 'The quick brown fox google.com the ipaddr of 10.10.10.1
',
	'flair' => '<div>The quick brown fox <span class="entity domain" data-entity-type="domain" data-entity-value="google.com">google.com</span> the ipaddr of <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span></div>'
};
delete $results->{cache};
say Dumper($results);
cmp_deeply ($results, $expect, "Flaired correctly");

is ($entry->body_flair, $expect->{flair}, "Entry flair was updated");
is ($entry->body_plain, $expect->{text}, "Entry plaintext was updated");

$env->log->debug("results: ",{filter=>\&Dumper, value=>$results});

$env->log->debug("IMAGE Tests");
my $imgentry = create_image_entry();
system("rm -f /tmp/cached_images/2021/entry/".$imgentry->id);
my $newhtml = $processor->preprocess_body($imgentry);
my $expecthtml = '<body><h1>Data URI</h1><img alt="Scot Copy of datauri" src="/cached_images/e7e370c66fe37ee469478719e8d3cea3.png" /><h1>Image from Elsewhere</h1><img alt="Scot Copy of energy_crest.png" src="/cached_images/7d1eaaa9a56fdc05890c137c797d50f5.png" /></body>';

is ($newhtml, $expecthtml, "Imgmunger handled images");
ok (-e "/tmp/cached_images/2021/entry/".$imgentry->id."/e7e370c66fe37ee469478719e8d3cea3.png", "data uri file written");
ok (-e "/tmp/cached_images/2021/entry/".$imgentry->id."/7d1eaaa9a56fdc05890c137c797d50f5.png", "external file written");

say Dumper($newhtml);


done_testing();

sub create_image_entry {
    my $html    = <<EOF;
        <html>
            <body>
                <h1>Data URI</h1>
    <img alt="SCOT_Logo64x64.png" src="data:image/png;base64,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"/>
                <h1>Image from Elsewhere</h1>
                    <img src="https://www.energy.gov/themes/particle/dist/app-drupal/assets/energy_crest.png" alt="Energy.Gov logo" class="image img-fluid">
            </body>
        </html>
EOF
# create an entry object
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Entry');
    my $entry   = $col->create({
        class	=> 'entry',
        metadata	=> {},
        parent  => 0,
        body    => $html,
        body_flair => $html,
        parsed  => 0,
        groups  => {
            read    => [ 'wg-scot-ir' ],
            modify  => [ 'wg-scot-ir' ],
        },
        owner   => 'scot-test',
        target  => { type => 'event', id => 1 },
        tlp     => 'amber',
    });
    return $entry;
}

sub create_event {
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Event');
    my $data    = {
        subject => "test event",
        source  => ["test"],
        tag     => ["test"],
        status  => 'open',
        groups  => {
            read    => [ 'wg-scot-test' ],
            modify  => [ 'wg-scot-test' ],
        },
    };
    return $col->api_create({
        user    => 'scot-test',
        request => {
            json    => $data
        },
    });
}
