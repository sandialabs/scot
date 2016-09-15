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
use Crypt::PBKDF2;
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

prompt(-e => '*', -p => "Password: ");
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

sub create_user {
    
    prompt "Enter new username: ";
    my $newuser = $_;

    my $pass1 = "1";
    my $pass2 = "2";
    while ( $pass1 ne $pass2 ) {
        prompt(-e=>'*',-p=> "$newuser password:");
        $pass1   = $_;
        prompt(-e=>'*',-p=> "verify $newuser password:");
        $pass2   = $_;
    }
    my $password    = $pass1;


    prompt -d => 'wg-scot', -p => "Enter group list (comma seperated): ";
    my $group   = $_;

    prompt "$newuser Fullname: ";
    my $gecos   = $_;

    my $pbkdf2  = Crypt::PBKDF2->new(
        hash_class  => 'HMACSHA2',
        hash_args   => { sha_size => 512 },
        iterations  => 10000,
        salt_len    => 15,
    );

    my $hash        = $pbkdf2->generate($password);
    my $json        = {
        type    => "user",
        data    => {
            username    => $newuser,
            hash        => $hash,
            local_acct  => 1,
            active      => 1,
            fullname    => $gecos,
            groups      => [ split(',',$group) ],
        },
    };

    say Dumper($json);

    if ( $client->post($json) ) {
        say "Created user $newuser";
    }
    else {
        say "ERROR creating $newuser!";
    }
}

sub reset_user {
    
    prompt "Enter username to reset: ";
    my $user    = $_;

    my $pass1   = "1";
    my $pass2   = "2";

    while ( $pass1 ne $pass2 ) {
        prompt( -e => '*', -p => "       new password: ");
        $pass1 = $_;
        prompt( -e => '*', -p => "verify new password: ");
        $pass2 = $_;
    }

    my $pbkdf2  = Crypt::PBKDF2->new(
        hash_class  => 'HMACSHA2',
        hash_args   => { sha_size => 512 },
        iterations  => 10000,
        salt_len    => 15,
    );

    my $password    = $pass2;

    my $hash        = $pbkdf2->generate($password);
    my $json        = {
        type    => "user",
        data    => {
            hash        => $hash,
            active      => 1,
        },
    };

    say Dumper($json);

    my $user_href   = $client->get({
        type    => "user",
        params  => {
            username    => $user
        },
    });

    unless ( $user_href->{id} ) {
        say "ERROR: user doesnt exist or is missing unique id";
        return undef;
    }
    say "User $user exists with id $user_href->{id}";

    if ( $client->put({
        id  => $user_href->{id},
        type    => "user",
        data    => $json
    })) {
        say "updated user $user password";
    }
    else {
        say "Error updating $user password";
    }
}
            



exit 0;
