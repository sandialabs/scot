#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use HTML::Entities;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Scot::Util::EntityExtractor;
use Parallel::ForkManager;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}   = "testing";
$ENV{'SCOT_AUTH_TYPE'}   = "Testing";
$ENV{'scot_env_configfile'} = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';
print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");

# fork and run Scot::App::Flair

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;

my $ee  = Scot::Util::EntityExtractor->new({
    log => $env->log,
});

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => ["firetest"],
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => qq| 
            google.com was providing 10.12.14.16 as the ipaddress
        |,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/entry/$entry2")
    ->status_is(200);

my $entrydata = $t->tx->res->json;

### put entity enrich
my $eehref = $ee->process_html($entrydata->{body});
my $json   = {
    parsed  => 1,
    body_plain  => $eehref->{text},
    body_flair  => $eehref->{flair},
    entities    => $eehref->{entities},
};

$t  ->put_ok("/scot/api/v2/entry/$entry2" => json => $json)
    ->status_is(200);



$t  ->get_ok("/scot/api/v2/event/$event_id/entity")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/google.com/type'   => 'domain')
    ->json_is('/records/10.12.14.16/type'   => 'ipaddr');

my $googleid = $t->tx->res->json->{records}->{'google.com'}->{id};
my $ipid     = $t->tx->res->json->{records}->{'10.12.14.16'}->{id};


$t  ->get_ok("/scot/api/v2/entity/$googleid/event")
    ->status_is(200)
    ->json_is('/records/0/id'       => 1)
    ->json_is('/records/0/subject'  => 'Test Event 1');
    
#print Dumper($t->tx->res->json),"\n";
#done_testing();
#exit 0;

$t  ->get_ok("/scot/api/v2/entity/$ipid/event")
    ->status_is(200)
    ->json_is('/records/0/id'       => 1)
    ->json_is('/records/0/subject'  => 'Test Event 1');

$t  ->post_ok('/scot/api/v2/entry'  => json => {
    body    => qq|
        chosun.com apture.com and cnomy.com
    |,
    target_id   => $event_id,
    target_type => "event",
    parent      => 0,
})->status_is(200)
    ->json_is('/status' => 'ok');

my $sidd_entry_id = $t->tx->res->json->{id};
$t  ->get_ok("/scot/api/v2/entry/$sidd_entry_id")
    ->status_is(200);
my $siddentrydata   = $t->tx->res->json;
my $eehref = $ee->process_html($siddentrydata->{body});
# print Dumper($eehref);
my $json   = {
    parsed  => 1,
    body_plain  => $eehref->{text},
    body_flair  => $eehref->{flair},
    entities    => $eehref->{entities},
};

$t  ->put_ok("/scot/api/v2/entry/$sidd_entry_id" => json => $json)
    ->status_is(200);

$t->get_ok("/scot/api/v2/entry/$sidd_entry_id/entity")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 3)
    ->json_is('/records/chosun.com/type'    => 'domain');

my $eid1 = $t->tx->res->json->{records}->{'chosun.com'}->{id};
my $eid2 = $t->tx->res->json->{records}->{'apture.com'}->{id};
my $eid3 = $t->tx->res->json->{records}->{'cnomy.com'}->{id};

$t->get_ok("/scot/api/v2/entity/$eid1")
    ->status_is(200);

my $agdata = [
            { foo   => 'cnn.com',   bar => '2.2.2.2' },
            { foo   => 'reddit.com',   bar => '4.4.4.4' },
        ];

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => $agdata,
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);
my $alertgroup_id   = $t->tx->res->json->{id};

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert")
    ->status_is(200);

my $retagdata = $t->tx->res->json->{records};

foreach my $ahref (@$retagdata) {
    my $flair   = {};
    TUPLE:
    while ( my ( $key, $value ) = each %{$ahref->{data}} ) {

        my $encoded = encode_entities($value);
        $encoded = '<html>'.$encoded.'</html>';

        if ( $key =~ /^message_id$/i ) {
            $flair->{$key} = $value;
            # might have do something like: (if process_html doesn't catch it) 
            # $flair->{$key} = $extractor->do_span(undef, "message_id", $value)
            # TODO create a test for this case
            push @entities, { value => $value, type => "message_id" };
            $flair->{$key} = qq|<span class="entity message_id" |.
                             qq| data-entity-value="$value" |.
                             qq| data-entity-type="message_id">$value</span>|;
            next TUPLE;
        }

        # note self on monday.  this isn't working find out why.
        my $eehref  = $ee->process_html($encoded);

        $flair->{$key} = $eehref->{flair};

        foreach my $entity_href (@{$eehref->{entities}}) {
            my $value   = $entity_href->{value};
            my $type    = $entity_href->{type};
            unless (defined $seen{$value}) {
                push @entities, $entity_href;
                $seen{$value}++;
            }
        }
    }
    $t->put_ok("/scot/api/v2/alert/$ahref->{id}" => json => {
        data_with_flair => $flair,
        entities        => \@entities,
        parsed          => 1,
    })->status_is(200);
}

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/entity")
->status_is(200);

 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



