#!/usr/bin/perl

use Crypt::PBKDF2;
use IO::Prompt;

my $pass    = prompt("Enter New Admin Password : ", -e => '*');
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
