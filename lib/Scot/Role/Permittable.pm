package Scot::Role::Permittable;

use Moose::Role;
use namespace::autoclean;

=item B<readgroups>

Array of groups that can read/view a record

=cut

has readgroups  => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_default_readgroups',
);

sub _default_readgroups {
    my $self    = shift;
    my $env     = $self->env;
    return $env->default_groups->{readgroups};
}

=item B<modifygroups>

Array of groups that can modify/delete a record

=cut

has modifygroups  => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_default_modifygroups',
);

sub _default_modifygroups {
    my $self    = shift;
    my $env     = $self->env;
    return $env->default_groups->{modifygroups};
}


sub is_readable {
    my $self                = shift;
    my $user_read           = shift;
    my $rg                  = $self->readgroups;
    return $self->is_permitted($user_read, $rg);
}

sub is_modifiable {
    my $self                = shift;
    my $user_modify         = shift;
    my $mg                  = $self->modifygroups;

    return $self->is_permitted($user_modify, $mg);
}

sub is_permitted {
    my $self                = shift;
    my $users_groups_aref   = shift;
    my $this_obj_groups     = shift;

    foreach my $group (@$users_groups_aref) {
        if ( grep { /^$group$/ } @{$this_obj_groups} ) {
            return 1;
        }
    }
    return undef;
}

sub set_default_groups {
    my $self        = shift;
    my $groups_aref = shift;

    if ( scalar( @{$self->readgroups} ) < 1 ) {
        $self->add_read_group($groups_aref->[0]);
    }
    if ( scalar( @{$self->modifygroups} ) < 1 ) {
        $self->add_modify_group($groups_aref->[0]);
    }
}

1;

