#!/usr/bin/env perl
use lib '../lib';
use Scot::Env;
use Scot::Util::Scot2;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use File::Slurp;
use Test::JSON;
use Proc::InvokeEditor;
use IO::Prompt;
use v5.18;

my $logfile     = "/var/log/scot/user_admin.log";
my $server      = "127.0.0.1";  # domain names will work too
my $path        = "/scot/api/v2/user";
my $jsonfile    = "";
my $verb        = "";

GetOptions(
    "log=s"     => \$logfile,
    "server=s"  => \$server,
) or die <<EOF

Invalid Option!

    usage: $0
        [-log=/tmp/ua.log]          Set the file for logging (def: /var/log/scot/ua.log)
        [-server=scotsrvr]          Set the SCOT server you wish to communicate with (def: 127.0.0.1)
                                        not setting this will allow you to enter interactively.
EOF
;

say "Log into SCOT";
prompt "Username: ";
my $user    = $_;

prompt( -e => '*', -p => "Password: ");
my $pass    = $_;


my $client  = Scot::Util::Scot2->new({
    servername  => $server,
    username    => $user,
    password    => $pass,
});

my $entry = "continue";

while ( $entry eq "continue" ) {
    prompt( -menu => {
        "Create User"       => "create",
        "Reset Password"    => "password",
        "Delete User"       => "delete",
        "quit"              => "quit",
    });

    my $action = $_;

    say $action;

    if ( $action eq "quit") {
        $entry = "no";
    }

    if ( $action eq "create" ) {
        create_user();
    }
    elsif ( $action eq "password" ) {
        reset_user();
    }
    elsif ( $action eq "delete") {
        delete_user();
    }
}



exit 0;
