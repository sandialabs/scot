package Scot::Role::Sharable;

use Moose::Role;
use namespace::autoclean;

# everything that has permissions should have an owner
# default owner is  a configuration item in env

has site   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_get_site',
);

sub _get_site {
    my $self    = shift;
    my $env     = Scot::Env->instance;
    return $env->site_identifier;
}

has shareable   => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    lazy        => 1,
    builder     => '_get_shareable',
);

sub _get_shareable {
    my $self    = shift;
    my $env     = Scot::Env->instance;
    my $log     = $env->log;

    # only tricky one is entry.  
    # if target is not_shareable, adopt that by default

    if ( ref($self) eq "Scot::Model::Entry" ) {
        # on second thought, this should be handled in API at create time
    }
    return $env->default_share_policy;
}

sub is_shareable {
    my $self            = shift;
    my $env             = Scot::Env->instance;
    my $log             = $env->log;
    return $self->shareable
}

# typo is several places
sub is_sharable {
    my $self    = shift;
    return $self->is_shareable;
}

1;
