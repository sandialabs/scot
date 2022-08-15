#!/usr/bin/env perl
use strict;
use warnings;
use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
system("/usr/bin/mongo scot-test ./reset.js");

require_ok('Scot::Flair::Io');

my $io = Scot::Flair::Io->new({env => $env});

ok(defined $io, "IO module instantiated");


my $mongo   = $env->mongo;
my $col     = $mongo->collection('Entry');
my $entry   = $col->create({
    target  => {
        id  => 1,
        type    => 'event',
    },
    owner   => 'test',
    groups  => {
        read    => ['wg-scot-ir'],
        modify  => ['wg-scot-ir'],
    },
    body    => "<html><h1>This is a test</h1><html>",
});

my $fetched_entry = $io->get_object("entry", $entry->id);

ok (defined $fetched_entry, "Got something from io");
ok (ref($fetched_entry) eq "Scot::Model::Entry", "and its the right thing");
ok ($fetched_entry->body eq $entry->body, "Bodies match");

my $body = qq|
    <html>
        <table>
            <tr><th>column_a</th><th>column_b</th></tr>
            <tr><td>val_a_1</td><td>val_b_1</td></tr>
            <tr><td>val_a_2</td><td>val_b_2</td></tr>
        </table>
    </html>
|;

my $alertgroup1    = $mongo->collection('Alertgroup')->create(
    message_id      => '6c9eeb6b6160930c65830841c8fe5378@foo.com',
    open_count      => 1,
    closed_count    => 1,
    promoted_count  => 1,
    alert_count     => 3,
    subject         => "Test Subject One",
    parsed          => 0,
    body_html       => $body,
);

ok (defined $alertgroup1, "alertgroup 1 created");
is ($alertgroup1->id, 1, "ID correct");
is ($alertgroup1->alert_count, 3, "Alert count correct"); # should be 2, but...

my $alert1  = $mongo->collection('Alert')->create({
    alertgroup  => $alertgroup1->id,
    status      => 'open',
    parsed      => 0,
    data        => { column_a => 'val_a_1', column_b => 'val_b_1' },
});
ok (defined $alert1, "alert 1 created");
my $alert2  = $mongo->collection('Alert')->create({
    alertgroup  => $alertgroup1->id,
    status      => 'open',
    parsed      => 0,
    data        => { column_a => 'val_a_2', column_b => 'val_b_2' },
});
ok (defined $alert2, "alert 2 created");


my $alert_cursor    = $io->get_alerts($alertgroup1);
my @alerts          = ();

while ( my $alert   = $alert_cursor->next ) {
    my $href    = $alert->as_hash;
    push @alerts, $href;
}
# print Dumper(\@alerts);

is ( $alerts[0]->{data}->{column_a}, 'val_a_1', 'a1 matches');
is ( $alerts[0]->{data}->{column_b}, 'val_b_1', 'b1 matches');
is ( $alerts[1]->{data}->{column_a}, 'val_a_2', 'a2 matches');
is ( $alerts[1]->{data}->{column_b}, 'val_b_2', 'b2 matches');

my $alert1_edb      = { 'foo'    => { 'val_a_1'   => 1 } };

my $alert1_results  = {
    'column_a'  => '<span class="foo">val_a_1</span>',
    'column_b'  => 'val_b_1',
};

my $alert2_edb      = { 'bar'    => { 'val_b_1'   => 1 } };

my $alert2_results  = {
    'column_a'  => '<span class="bar">val_a_2</span>',
    'column_b'  => 'val_b_2',
};

my $ag1_edb     = {
    'foo' => { 'val_a_1' => 1 },
    'bar' => { 'val_b_1' => 1 },
};

print "updating alert1\n";
$io->update_alert($alert1->id, $alert1_edb, $alert1_results);
print "updating alert2\n";
$io->update_alert($alert2->id, $alert2_edb, $alert2_results);
print "updating alertgroup1\n";
$io->update_alertgroup($alertgroup1->id, $ag1_edb);

my $updated_alert_cursor = $io->get_alerts($alertgroup1);
my @new_alerts =();
while ( my $alert = $updated_alert_cursor->next ) {
    my $href    = $alert->as_hash;
    push @new_alerts, $href;
}

is ( $new_alerts[0]->{data_with_flair}->{column_a}, $alert1_results->{column_a}, "Alert 1 data_with_flair correct");
is ( $new_alerts[1]->{data_with_flair}->{column_a}, $alert2_results->{column_a}, "Alert 2 data_with_flair correct");

my @links = ();
my $link_cursor = $mongo->collection('Link')->find({});
while (my $l = $link_cursor->next ) {
    my $href = $l->as_hash;
    push @links, $href;
}

is ( $links[0]->{vertices}->[0]->{type}, "alert", "link 0 vertice 0 type");
is ( $links[0]->{vertices}->[0]->{id},   1,       "link 0 vertice 0 id");

is ( $links[1]->{vertices}->[0]->{type}, "alert", "link 1 vertice 0 type");
is ( $links[1]->{vertices}->[0]->{id},   2,       "link 1 vertice 0 id");

is ( $links[2]->{vertices}->[0]->{type}, "alertgroup", "link 2 vertice 0 type");
is ( $links[2]->{vertices}->[0]->{id},   1,            "link 2 vertice 0 id");
is ( $links[2]->{vertices}->[1]->{type}, "entity",     "link 2 vertice 1 type");
is ( $links[2]->{vertices}->[1]->{id},   1,            "link 2 vertice 1 id");

is ( $links[3]->{vertices}->[0]->{type}, "alertgroup", "link 3 vertice 0 type");
is ( $links[3]->{vertices}->[0]->{id},   1,            "link 3 vertice 0 id");
is ( $links[3]->{vertices}->[1]->{type}, "entity",     "link 3 vertice 1 type");
is ( $links[3]->{vertices}->[1]->{id},   2,            "link 3 vertice 1 id");

done_testing();
exit 0;
