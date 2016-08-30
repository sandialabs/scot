#!/usr/bin/env perl
use lib '../lib';
use Scot::Env;
use Scot::Util::Scot;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use File::Slurp;
use Test::JSON;
use Proc::InvokeEditor;
use IO::Prompt;
use v5.18;

my $logfile     = "/var/log/scot/user_admin.log";
my $server      = "127.0.0.1";  # domain names will work too
my $path        = "";
my $jsonfile    = "";
my $verb        = "";

GetOptions(
    "log=s"     => \$logfile,
    "server=s"  => \$server,
    "path=s"   => \$path,
    "json=s"    => \$jsonfile,
    "action=s"  => \$verb,
) or die <<EOF

Invalid Option!

    usage: $0
        [-log=/tmp/ua.log]          Set the file for logging (def: /var/log/scot/ua.log)
        [-server=scotsrvr]          Set the SCOT server you wish to communicate with (def: 127.0.0.1)
        [-action=http_verb]         Set the HTTP verb {get|put|post|delete} you want to perform
        [-path=/scot/api/v2/event]  Set the REST endpoint. Not setting will prompt you interactively.
        [-json=/tmp/data.json]      Set the JSON you wish to send with request. 
                                        not setting this will allow you to enter interactively.
EOF
;



my $env = Scot::Env->new({
    logfile => $logfile,
});

my $client  = Scot::Util::Scot->new({
    servername  => $server,
});

ACTION:
while ( $action eq "" ) {
    $action    = prompt "Enter Action (list|add|delete|change|quit)> ";

    unless ( grep {/$action/} qw(list add delete change quit) ) {
        say "Invalid action!"
        next ACTION;
    }
    if ( $action eq "list" ) {
        list();
    }
    elsif ( $action eq "add" ) {
        add();
    }
    elsif ( $action eq "delete" ) {
        delete();
    }
    elsif ( $action eq "change" ) {
        change();
    }
    else ( $action eq "quit" ) {
        exit 0;
    }
}

sub list {
    say "coming soon...";
}

sub add {

}


prompt -menu=>{
    "Enter JSON in VIM" => 1,
    "Load JSON from File" => 2,
    "No JSON" => 3,
};

print "You selected $_\n";
my $json;

if ( $_ == 1 ) {
    $json = Proc::InvokeEditor->edit("");
    unless ( is_valid_json $json ) {
        die "JSON input is invalid! ". Dumper($json)."\n";
    }
}

if ( $_ == 2 ) {
    unless ( $jsonfile ) {
        $jsonfile = prompt "Enter filename for JSON > ";
    }
    $json = read_file($jsonfile);
    unless ( is_valid_json $json ) {
        die "JSON input is invalid! ". Dumper($json)."\n";
    }
}

if ( $_ == 3 ) {
    undef $json;
}

my $tx;
if ( $json ) {
    $tx = $client->$verb($path, $json);
}
else {
    $tx = $client->$verb($path);
}

if ( my $res = $tx->success ) {
    print Dumper($tx->res->json)."\n";
}
else {
    print "Error! ".Dumper($tx);
}

exit 0;
