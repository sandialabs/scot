#!/usr/bin/env perl
use lib '../lib';
use Scot::Model::Alert;
use Scot::Util::Mongo;
use Log::Log4perl;
use Data::Dumper;
use Test::More qw(no_plan);
use Test::Deep;
use MongoDB::OID;
# use Test::More  tests => 10;


BEGIN {
    use_ok('Scot::Model::Alert');
};
END {
#    $mongo->dropdatabase;
}

my $log;
Log::Log4perl->init('../etc/logging.test.conf');
$log = Log::Log4perl->get_logger;

my $session = {
    groups  => [ qw(test prod) ],
};

my $test_config = {
    mongo   => {
        host    => "mongodb://localhost",
        db_name => "scotng-test",
        port    => 27017,
        user    => "scot",
        pass    => "scotpass",
        find_master     => 1,
        write_safety    => 1,
    }
};

$mongo = Scot::Util::Mongo->new({
        'log'       => $log,
        'config'    => $test_config,
});
ok(defined($mongo), "create Scot::Util::Mongo object");
$mongo->dropdatabase;


$log->debug("----- Beginning Test ------");

my $time    = time();

my $oid = MongoDB::OID->new(value=>"1234");

my $orig_href   = {
    _id         => $oid,
    alert_id    => 1,
    status      => 'new',
    created     => $time,
    updated     => $time,
    when        => $time,
    sources     => [ qw(foo bar boom) ],
    tags        => [ qw(tag1 tag2 tag3) ],
    viewed_by   => [ ],
    files       => [ ],
    subject     => "test alert 1",
    body        => "this is a test alert.  please ignore",
    'log'       => $log,
};

my $alert   = Scot::Model::Alert->new($orig_href);

ok(defined($alert), "create Scot::Model::Alert object");

$alert->dump(); # see it in log

cmp_deeply(
    $alert, 
    methods(
        '_id'       => $oid,
        alert_id    => 1,
        status      => "new",
        created     => $time,
        updated     => $time,
        when        => $time,
        sources     => [ qw(foo bar boom) ],
        tags        => [ qw(tag1 tag2 tag3) ],
        viewed_by   => [ ],
        files       => [ ],
        subject     => "test alert 1",
        body        => "this is a test alert.  please ignore",
    ),
    "alert created correctly"
);

$alert->reset_oid;
$alert->add_read_group('test');
my $inserted_oid = $mongo->write_object($alert,$session);
is(ref($inserted_oid), 'MongoDB::OID', "Inserted Alert");

$alert->subject("Test Alert 2");
my $second_oid = $mongo->write_object($alert, $session);
isnt("$second_oid", "$inserted_oid", "second insertion generated new oid");



$log->debug("----- Ending Test ------");
