#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';
use Test::More;
use Test::Mojo;
use Test::Deep;
use Data::Dumper;

use Scot::Request::Alertgroup;

my $raw = {
    collection  => 'alertgroup',
    id          => 1,
    user        => 'tbruner',
    groups      => [qw(wg-scot-test wg-scot-ir)],
    params      => { 
        sort    => ['+id'],
        limit   => 100,
        skip    => 10,
    },
    json    => {
        subject => 'test1',
        data    => [
            {
                foo     => 'bar',
                boom    => [ qw(one two three) ],
                baz     => {
                    col1    => 'data1',
                },
            },
        ],
    },
};

my $request = Scot::Request::Alertgroup->new($raw);

ok(defined $request, "Request Object created with raw data");
is($request->collection, $raw->{collection}, "Collection is correct");
is($request->id, $raw->{id}, "Id is correct");
is($request->user, $raw->{user}, "User is correct");
is($request->groups->[0], $raw->{groups}->[0], "Group 0 is correct");
is($request->groups->[1], $raw->{groups}->[1], "Group 1 is correct");

my $got_groups = $request->build_groups_to_assign();
my $expect_groups   = {
    read    => [qw(wg-scot-test wg-scot-ir)],
    modify  => [qw(wg-scot-test wg-scot-ir)],
};
cmp_deeply($got_groups, $expect_groups, "group permissions set from users correctly");

my $create_href = $request->get_create_href;
# print Dumper($create_href);
cmp_bag($create_href->{columns}, [qw(baz boom foo)], "Columns are correct");
ok(defined $create_href->{message_id}, "Created a message_id");
is($create_href->{subject}, $raw->{json}->{subject}, "Subject is correct");
cmp_bag($create_href->{groups}->{read}, $expect_groups->{read}, "Read Groups set correctly");
cmp_bag($create_href->{groups}->{modify}, $expect_groups->{modify}, "Modify Groups set correctly");

my $got_message_id = $request->build_message_id({message_id => 'foo'});
is($got_message_id, "foo", "explicit set of message_id works");

my $raw_update  = {
    collection  => 'alertgroup',
    id          => 1,
    user        => 'tbruner',
    groups      => [qw(wg-scot-test wg-scot-ir)],
    json        => {
        parsed  => 1,
        updated => 123456,
        body    => 'oops',
    },
};
$request = Scot::Request::Alertgroup->new($raw_update);

my $got_update  = $request->get_update_href;
print Dumper($got_update);
is($got_update->{parsed}, 1, "parsed set correctly");
is($got_update->{updated}, 123456, "updated set correctly");
ok(! defined $got_update->{body}, "dropped body update");

done_testing();
exit 0;
