#!/usr/bin/perl

use Crypt::PBKDF2;

my $pbkdf2 = Crypt::PBKDF2->new(
        hash_class => 'HMACSHA2',
        hash_args => {
            sha_size => 512
        },
        iterations => 10000,
        salt_len => 15,
    );
my $pass = $ARGV[0];
chomp($pass);
# print $pass;
print $pbkdf2->generate($pass);
