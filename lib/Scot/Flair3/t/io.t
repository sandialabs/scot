#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use lib '../../../../lib';
use DateTime;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Log::Log4perl;
use Scot::Env;
use File::Slurp;
use Meerkat;

my $env = Scot::Env->new({config_file => './test.cfg.pl'});

system("killall topic.t");
system("rm -rf /tmp/test");
system("mongo scot-test < ./reset.js 2>&1");
system("./topic.t&");
print "Topic watcher spawned \n";
my $watchfile = "./rcv.txt";

my $log = Log::Log4perl->get_logger('flair_test');
my $pattern = "%d %7p [%P] %15F{1}: %4L %m%n";
my $layout  = Log::Log4perl::Layout::PatternLayout->new($pattern);
my $appender= Log::Log4perl::Appender->new(
    'Log::Log4perl::Appender::File',
    name        => 'flair_log',
    filename    => '/var/log/scot/test.log',
    autoflush   => 1,
    utf8        => 1,
);
$appender->layout($layout);
$log->add_appender($appender);
$log->level("TRACE");

my $mongo   = Meerkat->new(
    model_namespace         => 'Scot::Model',
    collection_namespace    => 'Scot::Collection',
    database_name           => 'scot-test',
    client_options          => {
        host        => 'mongodb://localhost',
        w           => 1,
        find_master => 1,
        socket_timeout_ms => 600000,
    }
);

ok(defined $mongo, "Meerkat was defined");
is(ref($mongo), "Meerkat", "correct type");

my $col = $mongo->collection('Entry');
is (ref($col), "Scot::Collection::Entry", "Got a collection");

my $queue   = "/queue/flairtest";
my $topic   = "/topic/scottest";

require_ok("Scot::Flair3::Io");
my $io  = Scot::Flair3::Io->new(
    log     => $log,
    mongo   => $mongo,
    queue   => $queue,
    topic   => $topic,
);

ok (defined $io, "IO was defined");
is (ref($io), "Scot::Flair3::Io", "The correct type");

$io->send_mq($queue, {
    action  => 'test',
    data    => {
        who     => 'the_tester',
        type    => 'foo',
        id      => 4,
    }
});

$io->connect_to_amq($queue, $topic);
my $frame   = $io->receive_frame();
my $msg     = $io->decode_frame($frame);
$io->ack_frame($frame);

is ($msg->{headers}->{destination}, $queue, "proper queue received");
is ($msg->{body}->{pid}, $$, "pid correct");
is( $msg->{body}->{data}->{type}, "foo", "type correct");
is( $msg->{body}->{data}->{id}, 4, "id correct");
is( $msg->{body}->{data}->{who}, "the_tester", "who is correct");

# must create an $env obj otherwise get default singleton
# because Scot::Collection uses $env.  need to fix that
my $env = Scot::Env->new({ config_file => './test.cfg.pl'});

my $entity = $mongo->collection('Entity')->create({
    value   => 'foo.com',
    type    => 'domain',
    classes => [ 'domain foodomain' ],
});
is(ref($entity), "Scot::Model::Entity", "Entity Created");
is($entity->id, 1, "First Entity");

my $entity1 = $mongo->collection('Entity')->create({
    value   => 'bar.com',
    type    => 'domain',
    classes => [ 'domain' ],
});
is(ref($entity1), "Scot::Model::Entity", "Entity Created");
is($entity1->id, 2, "First Entity");


my $entry = $mongo->collection('Entry')->create({
    body        => "foobar was at foo.com",
    body_flair  => 'foobar was at <span class="entity domain foodomain" data-entity-type="domain" data-entity-value="foo.com">foo.com</span>',
    body_text   => 'foobar was at foo.com',
    target      => { type => 'event', id => 1 },
    parsed      => 1,
});
is (ref($entry), 'Scot::Model::Entry', "created an entry");
is ($entry->id, 1, "First entry");

my $event = $mongo->collection('Event')->create({
    subject => 'test event one',
});
is (ref($event), 'Scot::Model::Event', "created an event");
is ($event->id, 1, "First Event");

my $alertgroup = $mongo->collection('Alertgroup')->create({
    message_id  => '4',
    subject     => 'test alertgroup one',
    tags        => ['test', 'foo'],
    sources     => ['test', 'bar'],
});
is (ref($alertgroup), 'Scot::Model::Alertgroup', "Alertgroup created");
is ($alertgroup->id, 1, "first alertgroup");

my $created  = $mongo->collection('Alert')->linked_create({
    data    => {
        one => 'un', two => 'deux', three => 'trois'
    },
    subject => 'test alertgroup one',
    alertgroup  => $alertgroup->id,
    columns     => [ qw(one two three) ],
    owner       => 'foo',
    groups      => { read   => [ 'scot' ], modify => ['scot'] },
});
$created += $mongo->collection('Alert')->linked_create({
    data => {
        one => 'uno', two => 'dos', three => 'tres'
    },
    subject => 'test alertgroup one',
    alertgroup  => $alertgroup->id,
    columns     => [ qw(one two three) ],
    owner       => 'foo',
    groups      => { read   => [ 'scot' ], modify => ['scot'] },
});
is ($created, 2, "Created to alerts");

my @alerts  = ();
my $ac = $mongo->collection('Alert')->find({alertgroup => $alertgroup->id});
while (my $a = $ac->next) {
    push @alerts, $a;
}
is (scalar(@alerts), 2, "Found right number of alerts");
is ($alerts[0]->{data}->{one}, "un", "Row 0 column one correct");
is ($alerts[1]->{data}->{one}, "uno", "Row 1 column one correct");

my $link    = $io->link_objects($event, $alertgroup);
is ($link->vertices->[0]->{id}, 1, "Link vertice 0 ok");
is ($link->vertices->[0]->{type}, 'event', "Link vertice 0 ok");
is ($link->vertices->[1]->{id}, 1, "Link vertice 1 ok");
is ($link->vertices->[1]->{type}, 'alertgroup', "Link vertice 1 ok");

my $edb = {
    entities    => {
        domain  => {
            'foo.com'   => 1,
            'bar.com'   => 1,
        },
    },
};

$io->link_entities($event, $edb);
my $link_cursor = $mongo->collection('Link')->get_object_links($event);
my @links   = ();
while (my $l = $link_cursor->next) {
    push @links, $l;
}
is ($links[0]->vertices->[0]->{type}, "event", "vertice 0 type correct");
is ($links[0]->vertices->[1]->{type}, "alertgroup", "vertice 1 type correct");

# test to see if topics are sent.
# must start background process topic.t
my @lines   = read_file($watchfile);

$io->send_entry_updated_messages($entry);

sleep 1;
@lines = read_file($watchfile);
print Dumper(\@lines);
my $pid     = $lines[0];
system("kill $pid");

chomp(my $e1 = $lines[1]);
chomp(my $e2 = $lines[2]);
is($e1, "entry 1", "Received topic broadcast about entry 1");
is($e2, "event 1", "Received topic broadcast about event 1");

my $fqn = "/opt/scot/public/cached_images/foo.jpg";
is ($io->build_new_uri($fqn), "/cached_images/foo.jpg", "build_new_uri works");

my $nowyear = DateTime->now->year;
is ($io->get_entry_year($entry), $nowyear, "get_entry_year works");

my $tmpfile     = "/tmp/foo.jpg";
my $entry_id    = $entry->id;
is ($io->build_new_name($entry_id, $tmpfile), "/opt/scot/public/cached_images/$nowyear/$entry_id/foo.jpg", "build new name works");

is( $io->get_path($fqn), "/opt/scot/public/cached_images", "get_path works");

my $duri = "https://www.sandia.gov/app/uploads/sites/72/2021/06/scot.png";
my $tfn  = $io->download_img_uri($duri);

ok (-e $tfn, "downloaded file $tfn exists");

my $newloc = "/tmp/test/foo.jpg";
$io->move_file($tfn, $newloc);
ok (-e $newloc, "File moved");


done_testing();
exit 0;
