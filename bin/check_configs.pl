#!/usr/bin/env perl

use v5.18;

use lib '../lib';
use Scot::Env;
use Try::Tiny;
use Data::Compare;
use Data::Dumper;



my @required    = (
    {
        config_file => "/opt/scot/etc/scot.cfg.pl",
        install_ver => "../install/src/scot/scot.cfg.pl",
        attributes  => [
            "location",
            "site_identifier",
            "default_share_policy",
            "log_config",
            "modules",
            "get_method",
            "default_groups",
            "group_mode",
            "mode",
            "default_groups",
            "federation",
            "row_limit",
            "session_expiration",
            "admin_group",
            "file_store_root",
            "epoch_cols",
            "int_cols",
            "mojo_defaults",
            "entry_actions",
            "forms"
        ],
    },
    {
        config_file => "/opt/scot/etc/alert.cfg.pl",
        install_ver => "../install/src/scot/scot.cfg.pl",
        attributes  => [
            "location",
            "site_identifier",
            "default_share_policy",
            "time_zone",
            "log_config",
            "modules",
            "leave_unseen",
            "verbose",
            "max_processes",
            "fetch_mode",
            "since",
            "approved_alert_domains",
            "approved_accounts",
            "parser_dir",
            "default_groups",
            "default_owner",
        ],
    },
    {
        config_file => "/opt/scot/etc/flair.cfg.pl",
        install_ver => "../install/src/scot/flair.cfg.pl",
        attributes  => [
            "location",
            "site_identifier",
            "default_share_policy",
            "time_zone",
            "servername",
            "username",
            "password",
            "authtype",
            "log_config",
            "modules",
            "stomp_host",
            "stomp_port",
            "topic",
            "max_workers",
            "default_owner",
        ],
    },
    {
        config_file => "/opt/scot/etc/reflair.cfg.pl",
        install_ver => "../install/src/scot/reflair.cfg.pl",
        attributes  => [
            "location",
            "site_identifier",
            "time_zone",
            "servername",
            "username",
            "password",
            "authtype",
            "log_config",
            "modules",
            "stomp_host",
            "stomp_port",
            "topic",
            "max_workers",
        ],
    },
    {
        config_file => "/opt/scot/etc/backup.cfg.pl",
        install_ver => "../install/src/scot/backup.cfg.pl",
        attributes  => [
            "location",
            "log_config",
            "dbname",
            "pidfile",
            "bkuplocation",
            "cacheimg",
            "tarloc",
            "cleanup",
            "es_server",
            "es_backup_location",
        ],
    },
    {
        config_file => "/opt/scot/etc/restore.cfg.pl",
        install_ver => "../install/src/scot/restore.cfg.pl",
        attributes  => [
            "location",
            "log_config",
            "dbname",
            "pidfile",
            "bkuplocation",
            "cacheimg",
            "tarloc",
            "cleanup",
            "es_server",
            "es_backup_location",
        ],
    },
    {
        config_file => "/opt/scot/etc/game.cfg.pl",
        install_ver => "../install/src/scot/game.cfg.pl",
        attributes  => [
            "location",
            "log_config",
            "days_ago",
            "modules",
        ],
    },
    {
        config_file => "/opt/scot/etc/metrics.cfg.pl",
        install_ver => "../install/src/scot/metrics.cfg.pl",
        attributes  => [
            "time_zone",
            "log_config",
            "modules",
        ],
    },
    {
        config_file => "/opt/scot/etc/stretch.cfg.pl",
        install_ver => "../install/src/scot/stretch.cfg.pl",
        attributes  => [
            "location",
            "time_zone",
            "log_config",
            "max_workers",
            "stomp_host",
            "stomp_port",
            "topic",
            "default_owner",
            "modules",
        ],
    },
);

my @attrs_needed    = ();

foreach my $req (@required) {

    my $default = load_config($req->{install_ver});
    my $actual  = load_config($req->{config_file});

    foreach my $attr (@{$req->{attributes}}) {


        say "\nAttribute:    ".$attr;
        say "------------------------------\n";

        try {

            my $value   = $actual->{$attr};
            my $default = $default->{$attr};

            if ( defined $value ) {
                say "    attribute exists.";
            }
            else {
                push @attrs_needed, {
                    config => $req->{config_file},
                    attribute   => $attr,
                };
            }

            if ( examine($default, $value) ) {
                say "    attribute has default value";
            }
            else {
                say "    attribure has changed value";
            }
        }
        catch {
            say "    ERROR: attribute does not exist in ".
                $req->{config_file};
        };
    }
}

say "________________________________________________";
say "Missing Attributes in configs";
say "________________________________________________";
say Dumper(\@attrs_needed);

sub examine {
    my $def = shift;
    my $val = shift;
    return Compare($def, $val);
}

sub load_config {
    my $file    = shift;
    unless ( -r $file ) {
        die "Config file not readable!\n";
    };
    no strict 'refs';
    my $cont    = new Safe 'MCONFIG';
    my $result  = $cont->rdo($file);
    my $hname   = 'MCONFIG::environment';
    my %copy    = %$hname;
    my $href    = \%copy;
    return $href;
}


