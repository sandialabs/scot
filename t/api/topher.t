#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;
use Mojo::JSON qw(encode_json decode_json);

$ENV{'scot_mode'}           = "testing";
$ENV{'SCOT_AUTH_TYPE'}      = "Testing";
$ENV{'scot_log_file'}       = "/var/log/scot/scot.test.log";
$ENV{'scot_env_configfile'} = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';

print "Resetting test db...\n";
system("mongo scot-testing <../../etcsrc/database/reset.js 2>&1 > /dev/null");

@defgroups = ( 'ir', 'test' );

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;
#my $amq = $env->amq;
#$amq->subscribe("alert", "alert_queue");
#$amq->get_message(sub{
#    my ($self, $frame) = @_;
#    print "AMQ received: ". Dumper($frame). "\n";
#});

# use this to set csrf protection 
# though not really used due to testing auth 
$t->ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->header('X-Requested-With' => 'XMLHttpRequest');
});

#my $problem = '{"alert_message": "Rules flash.yara\\: \\{\\"name\\": \\"flash_cws\\" \\}"}';
#my $pp      = {
#    alert_message   => 'Rules flash.yara: { "name": "flash_cws" }'
#};
#
#my $pjson = encode_json($pp);
#print "JSON = $pjson\n";
#
#my $try = '{"alert_message":"Rules flash.yara: { \"name\": \"flash_cws\" }"}';
#my $x   = decode_json($try);
#print Dumper($x)."\n";
#exit 0;

my $json_txt = <<'EOF';
{
     "source": ["email", "splunk"], 
     "data": [
         {
             "mail_from": "james.m.robinson.mil@mail.mil", 
             "parent_types": "PDF_FILE", 
             "name": "[Non-DoD Source] ADOS-AC Opportunity for Signal Soldiers.pdf.obj_129-0.pdf_stream", 
             "parent_names": "[Non-DoD Source] ADOS-AC Opportunity for Signal Soldiers.pdf",
             "mail_subject": "Tonight\\'s Conference call  (UNCLASSIFIED)",
             "alert_level": "5",
             "hybrid_uuid": "06e5bd0cefd5489384292ecb8cd8596d",
             "mail_to": "scott.madison@gmail.com, robert.a.ramos.mil@mail.mil, joseph.a.england8.mil@mail.mil, vincent.d.pegues.mil@mail.mil, bernadette.a.banderas.mil@mail.mil, tturnipseed@utep.edu, timothy.j.turnipseed.mil@mail.mil, tommy.m.truex@gmail.com, eric.s.marsh4.mil@mail.mil, gracia.gillies@ssa.gov, timothy.d.allen30.mil@mail.mil, marlin.j.wilson2.mil@mail.mil, tommy.m.truex.mil@mail.mil, joseph.l.shendo.mil@mail.mil, kcbouch@sandia.gov, thomas.d.vitale.mil@mail.mil, christy.c.erkins.mil@mail.mil, scott.madison.mil@gmail.com, joseph.p.krick.mil@mail.mil, keli.boucher@gmail.com, wesley.a.mercer.mil@mail.mil, john.calloway.mil@mail.mil, thomas.e.brewer6.mil@mail.mil, ceodis.lasker.mil@mail.mil, keli.c.boucher.mil@mail.mil, john.c.schmidt.mil@mail.mil, gracia.y.gillies.mil@mail.mil, moriah.d.johnson.mil@mail.mil, christy.erkins@yahoo.com, dskantorowicz@live.com", 
             "mail_direction": "incoming", 
             "quarantined": "false", 
             "message_id": "b05bf8ab1a2346b6bf94e2a086d70b9e@UGUNHU2E.easf.csd.disa.mil", 
             "alert_message": "Rules flash.yara: { \"name\": \"flash_cws\" }",
             "alert_chip": "YaraChip", 
             "datetime": "2016-11-15 21:53:13Z", 
             "filetype": "Macromedia Flash data (compressed), version 9", 
             "md5": "01e2e8f36cfba4fb653992841e240f7e", 
             "filetypeclass": "FLASH_FILE"
         }
     ], 
     "message_id": "b195fc55-9226-47d7-a7a2-d687a085a3a1", 
     "columns": [
         "datetime", 
         "quarantined", 
         "alert_level", 
         "alert_message", 
         "mail_to", 
         "mail_from", 
         "mail_subject", 
         "mail_direction", 
         "name", 
         "filetypeclass", 
         "filetype", 
         "alert_chip", 
         "parent_names", 
         "parent_types", 
         "message_id", 
         "md5", 
         "hybrid_uuid"
     ], 
     "subject": "Splunk Alert: (CTN) MDS 2.0 Alert (>=5) resend because of splunk issue"
    }
EOF

print $json_txt."\n";
my $json = decode_json($json_txt);

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => $json
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};


$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id" => {},
    "Get alertgroup $alertgroup_id")
    ->status_is(200);

print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

