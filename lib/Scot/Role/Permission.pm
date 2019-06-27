package Scot::Role::Permission;
use Moose::Role;
use namespace::autoclean;

=head1 Name

Scot::Role::Permission

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<owner>

everything that has permissions should have an owner
default owner is  a configuration item in env

=cut

has owner   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_get_default_owner',
);

=item B<groups>

groups control who can read and modify the object
 {
   read    => [ group1, group2,..., groupn ],
   modify  => [ group3, group4,..., groupx ],
 }

=cut


has groups  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_get_default_groups',
);

sub _get_default_owner {
    my $self    = shift;
    my $env     = Scot::Env->instance;
    return $env->default_owner;
}

sub _get_default_groups {
    my $self    = shift;
    my $env     = Scot::Env->instance;
    return  $env->default_groups;
}

=back

=head1 Methods

This Role also provides the following methods:

=over 4

=item B<is_permitted($op_str, $user_group_set_aref)>

This method returns true if the user's group set intersects with the 
groups attribute array for the given op_str.  For example:

    # $obj->groups->{read} = [ "analyst", "investigator" ];
    @usergroups = (qw(researcher analyst));

    if ( $obj->is_permitted("read", \@usergroups) ) {
        say "User is permitted to read object";
    }

    output:
    User is permitted to read object

=cut

sub is_permitted {
    my $self            = shift;
    my $operation       = shift;
    my $users_groups    = shift;
    my $env             = Scot::Env->instance;
    my $log             = $env->log;

    my $perm_href   = $self->groups;
    my $perm_aref   = $perm_href->{$operation};

    unless (ref($users_groups) eq "ARRAY" ) {
        $users_groups = [ $users_groups ];
    }

    # force everything to lc to remove case sensitivity
    $log->debug("Permitted groups for $operation: " . 
                join(',', map {lc($_)} @{$perm_aref}) );

    $log->debug("Users groups are ". join(',', @{$users_groups}));

    foreach my $group ( @$users_groups ) {
        if ( grep { /^$group$/i } @{$perm_aref} ) {
            $log->debug("Group $group match");
            return 1;
        }
    }
    return undef;
}

=item B<is_readable($user_group_set_aref)>

Shortcut for C<is_permittable("read", $user_group_set_aref)>

=cut

sub is_readable {
    my $self                = shift;
    my $users_groups        = shift;
    return $self->is_permitted("read", $users_groups);
    
}

=item B<is_modifiable($user_group_set_aref)>

Shortcut for C<is_permittable("modify", $user_group_set_aref)>

=cut

sub is_modifiable {
    my $self            = shift;
    my $users_groups    = shift;
    return $self->is_permitted("modify", $users_groups);
}

=back

=cut

1;

