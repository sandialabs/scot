package Scot::Secret;

use strict;
use warnings;
use Crypt::CBC;
use File::Slurp;
use Moose;

has key     => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has file    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/opt/scot/etc/secrets',
);

has crypto  => (
    is          => 'ro',
    isa         => 'Crypt::CBC',
    required    => 1,
    lazy        => 1,
    builder     => '_build_crypto',
);

sub _build_crypto {
    my $self    = shift;
    my $key     = $self->key;
    my $cbc     = Crypt::CBC->new(
        -pass   => $key,
        -cipher => 'Blowfish',
        -pbkdf  => 'pbkdf2',
    );
    return $cbc;
}

# file structure is 
# component:username:encrypted_secret

sub read_secret_file {
    my $self        = shift;
    my $file        = $self->file;
    if ( ! -e $file ) {
        return wantarray ? () : [];
    }
    my @contents    = read_file($file);
    return wantarray ? @contents : \@contents;
}

sub write_secret_file {
    my $self    = shift;
    my $content = shift; # array ref
    my $file    = $self->file;
    write_file($file, {atomic => 1}, join("\n",@$content));
}

sub parse_line {
    my $self    = shift;
    my $line    = shift;
    return split(/:/,$line,3);
}

sub decrypt_secret {
    my $self    = shift;
    my $secret  = shift;
    my $plain   = $self->crypto->decrypt_hex($secret);
    return $plain;
}

sub encrypt_plain {
    my $self    = shift;
    my $plain   = shift;
    my $secret  = $self->crypto->encrypt_hex($plain);
    return $secret;
}

sub secret_count {
    my $self    = shift;
    my @content = $self->read_secret_file;
    return scalar(@content);
}

sub load_secret_db {
    my $self    = shift;
    my @content = $self->read_secret_file;
    my %db      = ();

    foreach my $line (@content) {
        my ($component, $user, $secret) = $self->parse_line($line);
        $db{$component}{$user} = $secret;
    }

    return wantarray ? %db : \%db;
}

sub write_secret_db {
    my $self    = shift;
    my $db      = shift;
    my @lines   = ();

    foreach my $component (sort keys %$db) {
        foreach my $user (sort keys %{$db->{$component}}) {
            push @lines, "$component:$user:".$db->{$component}->{$user};
        }
    }
    $self->write_secret_file(\@lines);
}

sub get_secret {
    my $self    = shift;
    my $comp    = shift;
    my $user    = shift;
    my %db      = $self->load_secret_db;
    my $secret  = $db{$comp}{$user};
    my $plain   = $self->decrypt_secret($secret);
    return $plain;
}

sub add_secret {
    my $self    = shift;
    my $comp    = shift;
    my $user    = shift;
    my $plain   = shift;
    my $db      = $self->load_secret_db;

    if ( defined $db->{$comp}->{$user} ) {
        return undef;
    }
    $db->{$comp}->{$user} = $self->encrypt_plain($plain);

    $self->write_secret_db($db);
}

sub update_secret {
    my $self    = shift;
    my $comp    = shift;
    my $user    = shift;
    my $plain   = shift;
    my $db      = $self->load_secret_db;

    $db->{$comp}->{$user} = $self->encrypt_plain($plain);
    $self->write_secret_db($db);
}

sub delete_secret {
    my $self    = shift;
    my $comp    = shift;
    my $user    = shift;
    my $plain   = shift;
    my $db      = $self->load_secret_db;
    delete $db->{$comp}->{$user};
    $self->write_secret_db($db);
}

1;


