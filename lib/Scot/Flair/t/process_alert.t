#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);


my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});

require_ok('Scot::Flair::Regex');
my $regex = Scot::Flair::Regex->new({env => $env});
ok(defined $regex, "Regex module instantiated");
ok(ref($regex) eq 'Scot::Flair::Regex', 'got what we expected');

require_ok('Scot::Flair::Io');
my $io = Scot::Flair::Io->new({env => $env});
ok(defined $io, "Scot::Flair::Io instantiated");
ok(ref($io) eq 'Scot::Flair::Io', 'got what we expected');

require_ok('Scot::Flair::Extractor');
my $extractor   = Scot::Flair::Extractor->new({
    env => $env,
    scot_regex => $regex,
});
ok(defined $extractor, "Extractor instantiated");
ok(ref($extractor) eq 'Scot::Flair::Extractor', 'got what we expected');


require_ok('Scot::Flair::Processor::Alertgroup');
my $processor = Scot::Flair::Processor::Alertgroup->new({
    env     => $env,
    regexes => $regex,
    scotio  => $io,
    extractor => $extractor,
});
ok(defined $processor, "Processor Instantiated");
ok(ref($processor) eq 'Scot::Flair::Processor::Alertgroup', 'got what we expected');

# create an alertgroup object
my $agdata  = {
    message_id  => '112233445566778899aabbccddeeff',
    subject     => 'test alertgroup',
    tlp         => 'white',
    created     => time(),
    updated     => time(),
    entry_count => 0,
    closed_count=> 0,
    open_count  => 1,
    alert_count => 1,
    body        => 'not necessary',
    body_plain  => 'na',
    status      => 'open',
    view_history=> {},
    ahrefs      => [],
    promotion_id => 0,
    parsed      => 0,
    firstview   => 1536161212,
    owner       => 'test',
    columns => [ 'col1', 'col2', 'col3', 'message_id', 'scanid', 'attachment_name', 'sparkline' ],
    groups      => {
        read    => ['wg-scot-ir'],
        modify  => ['wg-scot-ir'],
    },
    tag         => ['foo', 'bar'],
    source      => ['unknown'],
};
my $mongo   = $env->mongo;
my $col     = $mongo->collection('Alertgroup');
my $ag      = $col->create($agdata);
my $agid    = $ag->id;

my @adata   = (
    {   
        tlp => 'white',
        created => time(),
        updated => time(),
        parsed  => 1,
        groups  => { read=>['wg-scot-ir'], modify=>['wg-scot-ir'] },
        promotion_id => 0,
        entry_count => 0,
        alertgroup => $agid,
        owner   => 'test',
        location    => 'snl',
        when    => time(),
        data    => {
            columns => [ 'col1', 'col2', 'col3', 'message_id', 'scanid', 'attachment_name', 'sparkline' ],
            col1    => [ '10.10.10.1' ],
            col2    => [ 'sandia.gov' ],
            col3    => [ 'CVE-1970-12345', 'CVE-1971-124444' ],
            message_id  => [ '112233445566778899aabbccddeeff' ],
            scanid  => [ 'b8aef540-7720-11e7-9da3-65e99acc6ead' ],
            attachment_name => [ 'foobar.exe' ],
            sparkline => ['<div>##__SPARKLINE__##,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 </div>'],
            sentinel_incident_url => '<a href=\"https://portal.azure.com/#asset/Microsoft_Azure_Security_Insights/Incident/subscriptions/793ceb02-f1ff-4102-83e1-b96d3f3fxxxx/resourceGroups/ent-logs-rg/providers/Microsoft.OperationalInsights/workspaces/snl-siem-law/providers/Microsoft.SecurityInsights/Incidents/85023a3c-005f-4581-b187-daa37ff1xxxx\" target=\"_blank\"><img alt=\"view in Azure Sentinel\" src=\"/images/azure-sentinel.png\" /></a>',
        },
        columns => [ 'col1', 'col2', 'col3', 'message_id', 'scanid', 'attachment_name', 'sparkline' ],
        data_with_flair => {},
        status => 'open',
    },
);
$col = $mongo->collection('Alert');
foreach my $href (@adata) {
    my $a = $col->create($href);
}

my $agquery = { data => { type => "alertgroup", id => $agid } };

# flair it
my $agobj = $processor->retrieve($agquery);

my $expected = {
    entities    => [
		{ 'value' => 'b8aef540-7720-11e7-9da3-65e99acc6ead', 'type' => 'message_id' },
		{ 'type' => 'cve', 'value' => 'cve-1970-12345' },
		{ 'type' => 'cve', 'value' => 'cve-1971-124444' },
		{ 'type' => 'domain', 'value' => 'sandia.gov' },
		{ 'type' => 'ipaddr', 'value' => '10.10.10.1' },
		{ 'type' => 'filename', 'value' => 'foobar.exe' },
		{ 'type' => 'message_id', 'value' => '112233445566778899aabbccddeeff' },
	], 
	data_with_flair => {
       'scanid' => '<span class="entity message_id"  data-entity-value="b8aef540-7720-11e7-9da3-65e99acc6ead"  data-entity-type="message_id">b8aef540-7720-11e7-9da3-65e99acc6ead</span>',
		'col2' => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></div>',
       'attachment_name' => '<span class="entity filename"  data-entity-value="foobar.exe"  data-entity-type="filename">foobar.exe</span>',
       'col1' => '<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span></div>',
       'sentinel_incident_url' => '<a href="&lt;a href=\\&quot;https://portal.azure.com/#asset/Microsoft_Azure_Security_Insights/Incident/subscriptions/793ceb02-f1ff-4102-83e1-b96d3f3fxxxx/resourceGroups/ent-logs-rg/providers/Microsoft.OperationalInsights/workspaces/snl-siem-law/providers/Microsoft.SecurityInsights/Incidents/85023a3c-005f-4581-b187-daa37ff1xxxx\\&quot; target=\\&quot;_blank\\&quot;&gt;&lt;img alt=\\&quot;view in Azure Sentinel\\&quot; src=\\&quot;/images/azure-sentinel.png\\&quot; /&gt;&lt;/a&gt;" target="_blank"><img alt="view in Azure Sentinel" src="/images/azure-sentinel.png" /></a>',
       'col3' => '<div><span class="entity cve" data-entity-type="cve" data-entity-value="cve-1970-12345">CVE-1970-12345</span></div> <div><span class="entity cve" data-entity-type="cve" data-entity-value="cve-1971-124444">CVE-1971-124444</span></div>',
    },
	parsed => 1,
};

my $cursor = $io->get_alerts($agobj);
while ( my $alert = $cursor->next ) {

    is (ref($alert), "Scot::Model::Alert", "Got alert ".$alert->id);

    my $new_alert_data = $processor->flair_alert($alert);

	cmp_deeply($new_alert_data->{data_with_flair}, $expected->{data_with_flair}, "Got expected flair data");
    cmp_deeply($new_alert_data->{entities}, bag($expected->{entities}));
}



