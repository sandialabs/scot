#!/usr/bin/env perl

use Crypt::PBKDF2;
use IO::Prompt;

# sample code on how to generate password hashes for scot

my $passok = "no";
my $pass;
my $pass2;

while ($passok eq "no") {

    $pass    = prompt("Enter New Admin Password : ", -e => '*');
    $pass2   = prompt("Reenter Admin Password   : ", -e => '*');

    if ( $pass eq $pass2 ) {
        $passok = "yes";
    }
    else {
        print "!!! Passwords do not match !!!\n";
    }
}

my $pbkdf2  = Crypt::PBKDF2->new(
        hash_class => 'HMACSHA2',
        hash_args => {
            sha_size => 512
        },
        iterations => 10000,
        salt_len => 15,
    );
chomp($pass);
# print $pass;
print $pbkdf2->generate($pass);
print "\n";
