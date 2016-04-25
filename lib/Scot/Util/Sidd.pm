package Scot::Util::Sidd;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Carp qw/croak/;
use MongoDB::MongoClient;
use Data::Dumper;
use Try::Tiny::Retry 0.002 qw/:all/;
use Moose;

=head1 Name

Scot::Util::Sidd

=head1 Description

this module simplifies talking to the SIDD database

=cut

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
    default => sub { Scot::Env->instance },
);

=item B<servername>

this is the Sidd server

=cut

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_servername',
);

sub _get_servername {
    my $self    = shift;
    my $env     = $self->env;
    my $name    = $env->sidd_server // '127.0.0.1';
    return $name;
}

=item B<username>

the username to access scot

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_sidd_username',
);

sub _get_sidd_username {
    my $self    = shift;
    my $env     = $self->env;
    return $env->sidd->username // 'scot';
}

has password => ( 
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_sidd_user_pass',
);

sub _get_sidd_user_pass {
    my $self    = shift;
    my $env     = $self->env;
    return  $env->sidd->password // 'needtosetimapspass';
}

=item B<pid>

for detection of forks

=cut

has pid => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => sub { $$+0 },
);

has client => (
    is          => 'ro',
    isa         => 'MongoDB::MongoClient',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_client',
    builder     => '_build_mongo_client',
);

sub _build_mongo_client {
    my $self    = shift;
    my $client  = eval {
        MongoDB::MongoClient->new(
            host        => $self->servername,
            port        => 27017,
            password    => $self->password,
            username    => $self->username,
            ssl         => { 'SSL_verify_mode' => 0 },
            db_name     => 'sidd',
        );
    };
    if ($@) {
        $self->env->log->error("Failed to Connect to SIDD mongodb: $@");
        return undef;
    }

    return $client;
}


sub clear_cache {
    my $self    = shift;

    
    # this function will reset the pid and the client cache
    
    if ( $$ != $self->uapid ) {
        $self->env->log->debug("Fork detected, restablishing...");
        $self->uapid($$);
        $self->clear_ua;
    }
}

# copied from the excellent Meerkat::Collection
# would have used meerkat for all of this except
# i don't control the schema (and it varies) of the sidd db
# so writing models and collections would have been tough
sub try_mongo_op {
    my $self    = shift;
    my $act     = shift;
    my $cmd     = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("trying mongo op $act");
    
    return &retry(
        $cmd, @_,
        retry_if { /not connected/ },
        delay_exp { 5, 1e6 },
        on_retry { $self->clear_cache },
        catch { croak "$act error: $_" }
    );
}

sub get_data {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;
    my $log     = $self->env->log;

    $log->trace("Retrieving SIDD data for $value");

    my $client      = $self->client;
    my $db          = $client->get_database('sidd');
    my $collection  = $db->get_collection('sidd');
    my $match       = { identifier  => $value };

    my $href  = $self->try_mongo_op(
        find_one    => sub { $collection->find_one($match) },
    );
    return $href;
}

1;

