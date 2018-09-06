package Scot::Role::Sharable;
use Moose::Role;
use namespace::autoclean;

=head1 Name

Scot::Role::Sharable

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<site>

Site is a unique string that identifies a SCOT site.  Set this value in 
you /opt/scot/etc/scot.cfg.pl file

=cut

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

=item B<shareable>

Boolean value that states if sharing of the consuming object is permitted.

=cut

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

=back

=head1 Methods

This role provides the following method.

=over 4

=item B<is_shareable>

Return the value stored in the B<sharable> attribute

=back

=cut

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
