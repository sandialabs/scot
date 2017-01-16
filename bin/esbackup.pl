#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use lib '/opt/scot/lib';

# this only backs up elastic search
# provided as example code
# use backup.pl in production

use Scot::Util::Config;
use Scot::Env;
use DateTime;

my $cfgobj  = Scot::Util::Config->new({
    file    => 'backup.cfg',
    paths   => [ '/opt/scot/etc' ],
    location => '/opt/scotbackup',
});
my $config  = $cfgobj->get_config;
my $curl    = "curl -s";

my $repocmd = $config->{es_server}."/_snapshot/scot_backup";
my $repo_status = `$curl -XGET $repocmd`;
say $repo_status;

if ( $repo_status !~ /location\":$config->{es_backup_location}/ ) {
    say "ElasticSearch Repo backup is not storing snapshots in expected location";
    say "Fixing...";
    my $delstat = `$curl -XDELETE $repocmd`;
    say "delete status is: $delstat";
}
$repo_status = `$curl -XGET $repocmd`;
say $repo_status;

if ( $repo_status =~ /repository_missing_exception/ ) {

    say "Missing Repo, creating...";

    my $create_repo_template = <<'EOF';
%s/_snapshot/scot_backup -d '{
    "type": "fs",
    "settings": {
        "compress": "true",
        "location": "%s"
    }
}'
EOF

    my $create_repo_string = sprintf($create_repo_template, 
                                    $config->{es_server},
                                    $config->{es_backup_location});

    say "Creating Repo with: $create_repo_string";
    my $repocreatestat = `$curl -XPUT $create_repo_string`;
    say "create status = $repocreatestat";
}


my $escmd   = $config->{es_server}.
              "/_snapshot/scot_backup/snapshot_1";

say "Querying ElasticSearch for scot backp snapshot...";
say "$escmd";
my $snap_query  = `$curl -XGET $escmd`;
say "snap query = $snap_query";

say "Deleting existing snapshot...";
my $delstat = `$curl -XDELETE $escmd`;

say "delete status is: $delstat";

say "Requesting a Snapshot...";

my $status = `$curl -XPUT $escmd`;
say "status = $status";

unless ( $status =~ /accepted\":true/ ) {
    warn "Failed to create a snapshot! $status";
}
else {
    say "waiting for snapshot to complete...";
    my $completestatus = `$curl -XGET $escmd`;
    my $count = 0;
    while ( $completestatus !~ /SUCCESS/ ) {
        say "still working...";
        sleep 5;
        $completestatus = `$curl -XGET $escmd`;
        $count++;

        if ($count > 100 ) {
            warn "Snapshot did not complete in reasonable amount of time...";
            $completestatus = "SUCCESS";
        }
    }
}

say "Snapshot complete...";
