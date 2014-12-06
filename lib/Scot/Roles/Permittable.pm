package Scot::Roles::Permittable;

use Moose::Role;
use namespace::autoclean;

requires 'log';

=item C<readgroups>
    array ref of strings representing the groups that can "read/view" 
    the data in a model
=cut
has readgroups => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    builder     => '_build_default_read_grouplist',
    traits      => [ 'Array' ],
    handles     => {
        all_read_groups => 'elements',
        add_read_group  => 'push',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<modifygroups>
 array ref of strings representing the groups than can modify/delete
 the data in a model
=cut
has modifygroups => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    builder     => '_build_default_grouplist',
    traits      => [ 'Array' ],
    handles     => {
        all_mod_groups      => 'elements',
        add_mod_group       => 'push',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

sub _build_default_grouplist {
    my $self    = shift;
    return [ qw(ir) ];
}

sub _build_default_read_grouplist {
    my $self    = shift;
    return [ qw(ir researchers) ];
}

sub is_readable {
    my $self                = shift;
    my $users_groups_aref   = shift;
    my $rg                  = $self->readgroups;
    my $log                 = $self->log;

    $log->debug("Checking Read Permissions");

    return $self->is_permitted($users_groups_aref, $rg);
}

sub is_modifiable {
    my $self                = shift;
    my $users_groups_aref   = shift;
    my $mg                  = $self->modifygroups;
    my $log                 = $self->log;

    use Data::Dumper;

    $log->debug("Checking Modify Permissions");
    $log->debug("modifygroups are " .Dumper($mg));
    $log->debug("users groups are " .Dumper($users_groups_aref));

    return $self->is_permitted($users_groups_aref, $mg);
}

sub is_permitted {
    my $self                = shift;
    my $users_groups_aref   = shift;
    my $this_obj_groups     = shift;
    my $log                 = $self->log;

    $log->debug("Checking permissions");
    $log->debug("users group membership: ".Dumper($users_groups_aref));
    $log->debug("object groups allowed : ".Dumper($this_obj_groups));

    foreach my $group (@$users_groups_aref) {
        $log->debug("Is users group of $group permitted?");
        if ( grep { /^$group$/ } @{$this_obj_groups} ) {
            $log->debug("Users group of $group is permitted");
            return 1;
        }
        $log->trace("Sadly, no...");
    }
    $log->debug("Sorry no soup for you.");
    return undef;
}

sub set_default_groups {
    my $self        = shift;
    my $groups_aref = shift;
    my $log         = $self->log;
    
    $log->debug("Setting default groups...");
    $log->debug("readgroups:   ".Dumper($self->readgroups));
    $log->debug("modifygroups: ".Dumper($self->modifygroups));
    $log->debug("users groups: ".Dumper($groups_aref));

    if ( scalar( @{$self->readgroups} ) < 1 ) {
        $log->debug("objects readgroups non existant, adding $groups_aref->[0]");
        $self->add_read_group($groups_aref->[0]);
    }
    if ( scalar( @{$self->modifygroups} ) < 1 ) {
        $log->debug("objects modifygroups non existant, adding $groups_aref->[0]");
        $self->add_modify_group($groups_aref->[0]);
    }
}

1;

