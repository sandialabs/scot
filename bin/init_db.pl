#!/usr/bin/env perl

use lib '../lib';
use v5.10;
use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::JSON;
use DateTime;
use DateTime::Duration;
use IO::Prompt;
use Data::Dumper;


my $ua      = Mojo::UserAgent->new;
my $json    = Mojo::JSON->new;
my $user    = "admin";
my $pass    = shift @ARGV;
my $url     = "https://$user:$pass\@localhost/scot";

unless ($pass) {
    die "usage: $0 adminpassword \n".
        " the adminpassword is the password for the admin user\n";
}

my $tx  = $ua->get($url."/alertgroup");

my $status  = $tx->res->json->{status};
say Dumper($tx->res->json);

if   ( $status eq "ok" and $tx->res->json->{total_records} != 0 )  {
    say "====";
    say "==== WARNING: DATA exists in the database!";
    say "==== If you continue, this data will be destroyed ";
    say "==== with no hope of recovery.";
    say "====";
    my $c = prompt "Do you wish to continue? [y|n]: ";
    die unless ( $c =~ /y/i );
}

my $now = time();
my $sample_alertgroup = {
    sources => [ "scot" ],
    subject => "Welcome to SCOT",
    tags    => [ "info", "welcome" ],
    data    => [
        { time  => $now, event   => "SCOT was installed", },
        { time  => $now, event   => "Sample data installed", },
        { time  => $now, event   => "Please explore the DOCS", },
    ],
    columns => [ qw(time event) ],
    readgroups  => [ qw(scot) ],
    modifygroups => [ qw(scot) ],
};

   $tx      = $ua->post($url."/alertgroup" => json => $sample_alertgroup);
my $agid    = $tx->res->json->{id};
my $aids    = $tx->res->json->{alert_ids};

say "Created Alertgroup $agid ".Dumper($tx->res->json);

my $sample_event    = {
    subject     => "Sample Event",
    source      => "scot",
    readgroups  => [ "scot" ],
    modifygroups=> [ "scot" ],
    alert_id    => $aids->[0],
};

   $tx          = $ua->post($url."/event" => json => $sample_event);
my $event_id    = $tx->res->json->{id};

my $sample_entry    = {
    body            =>  "<H3>Welcome to SCOT</H3> <p>This is a sample entry ".
                        "on a sample event.  Look, example.com has flair!  ".
                        "So does this: scot-dev\@sandia.gov .</p>",
    target_id       => $event_id,
    target_type     => "event",
    readgroups      => [ "scot" ],
    modifygroups    => [ "scot" ],
};
   $tx          = $ua->post($url."/entry" => json => $sample_entry);
my $entry_id    = $tx->res->json->{id};

say "Created entry_id: $entry_id";

my $discovery_dt    = DateTime->now();
my $report_delta    = DateTime::Duration->new(hours => 2);
my $report_dt       = $discovery_dt + $report_delta;

my $sample_incident = {
    subject     => "Sample Incident",
    type        => "Type 1: Information Compromise",
    category    => "IMI-2",
    sensitivity => "PII",
    security_category => "low",
    readgroups      => [ "scot" ],
    modifygroups    => [ "scot" ],
    discovered      => $discovery_dt->epoch(),
    reported        => $report_dt->epoch(),
};

   $tx          = $ua->post($url."/incident" => json => $sample_incident);
my $incident_id = $tx->res->json->{id};

$sample_entry   = {
    body            =>  "<H3>Welcome to SCOT</H3><p>This is a sample entry ".
                        "on a sample incident.  </p>",
    target_id       => $incident_id,
    target_type     => "incident",
    readgroups      => [ "scot" ],
    modifygroups    => [ "scot" ],
};
$tx          = $ua->post($url."/entry" => json => $sample_entry);
$entry_id    = $tx->res->json->{id};
say "Created entry_id: $entry_id";

my $sample_intel   = {
    subject        => "SCOT Intel Sample",
    source         => "scot",
    tags            => [ "scot","test" ],
};
$tx          = $ua->post($url."/intel" => json => $sample_intel);
my $intel_id    = $tx->res->json->{id};

$sample_entry   = {
    body            =>  "<H3>Welcome to SCOT</H3><p>This is a sample entry ".
                        "on a sample Intel.  </p><p>This is also a special ".
                        "type of entry that is also a task.",
    target_id       => $intel_id,
    target_type     => "intel",
    readgroups      => [ "scot" ],
    modifygroups    => [ "scot" ],
    is_task         => 1,
};
$tx          = $ua->post($url."/entry" => json => $sample_entry);
$entry_id    = $tx->res->json->{id};
say "Created entry_id: $entry_id";

