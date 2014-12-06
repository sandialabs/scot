package Scot::Model::User;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME
 Scot::Model::User - a moose obj rep of a Scot User

=head1 DESCRIPTION

 Definition of an A User

=cut

extends 'Scot::Model';

=head2 Attributes

=cut

with (  
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
);

=item C<user_id>

=cut

has user_id => (
    is      => 'rw',
    isa     => 'Int',
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        admin_update_only      => 1,
    },
);

has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'user_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'users',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);


=item C<username>

 string representation of users login
 
=cut

has username      => (
    is          =>  'rw',
    isa         =>  'Str',
    required    =>  1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        admin_update_only      => 1,
        gridviewable => 1
    },
);

=item C<hash>

 string representation of users salted hashed password used for local auth only

=cut

has hash      => (
    is          =>  'rw',
    isa         =>  'Maybe[Str]',
    required    =>  1,
    default     =>  '',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 0
    },
);


has lockouts => (
    is      => 'rw',
    isa     => 'Int',
    required    =>  0,
    default     =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        admin_update_only      => 1,
    },
);

has attempts => (
    is      => 'rw',
    isa     => 'Int',
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        admin_update_only      => 1,
    },
);

has last_login_attempt => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        admin_update_only      => 1,
    },
);


=item C<fullname>

 string representation of users login

=cut

has fullname      => (
    is          =>  'rw',
    isa         =>  'Maybe[Str]',
    required    =>  1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    default	=> '',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item C<tzpref>

 string describing the timezone pref

=cut

has tzpref     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'MST7MDT',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<lastvisit>

 seconds epoch when user last accessed scot

=cut

has lastvisit     => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        alt_data_sub    => 'fmt_time',
        admin_update_only   => 1,
    },
);

=item C<last_activity_check>

 seconds epoch when user last checked for new activity

=cut

has last_activity_check     => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        admin_update_only   => 1,
    },
);

=item C<theme>

 string describing the theme the user wishes to use
 
=cut

has theme     => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => 'default',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

sub _empty_array {
    return [];
}

=item C<groups>

 array ref of groups a user belongs to (used only for local auth)

=cut

has groups   => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    builder     => '_empty_array',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1,
        admin_update_only   => 1,
    },
);

=item C<active>

 If this account is active (local auth only)

=cut

has active   => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    default     => 0,
    description => {
        serializable    => 1,
        gridviewable    => 1,
        admin_update_only   => 1,
    },
);

=item C<local_acct>

  if account is local (non-ldap)

=cut

has local_acct   => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    default     => 0,
    description => {
        serializable    => 1,
        gridviewable    => 1,
        admin_update_only   => 1,
    },
);


=item C<flair>

 hash ref of flair_items and boolean values

=cut

has flair   => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => "on",
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<display_orientation>

 vertical/horizontal

=cut

has display_orientation     => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => 'horizontal',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

around BUILDARGS     => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_==1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;

        my $href    = {
            username    => $json->{username},
            theme       => $json->{theme},
            flair       => $json->{flair},
            tzpref      => $json->{tzpref},
            env         => $_[0]->env,
        };
        return $class->$orig($href);
    }
    else {
        # fix to replace hashref flair to boolean
        return $class->$orig(@_);
    }
};

sub build_modification_cmd {
    my $self        = shift;
    my $controller  = shift;
    my $env         = $controller->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    my $request     = $controller->req;
    my $json        = $request->json;
    my $now         = $env->now;
    my $meta        = $self->meta;

    my $user    = $controller->session('user');

    if ( $user ne $self->username ) {
        $log->error("User $user tried to change ".$self->username);
        return {};
    }

    my @changes;
    my %data;

    $log->debug("Building modification mongo command for User");

    while ( my ( $k, $v ) = each %$json ) {
        
        my $attr        = $meta->get_attribute($k);
        my $admin_only  = $attr->description->{admin_update_only};

        if ( $admin_only ) {
            $log->error("tried to update an admin_only field: $k");
            next;
        }

        my $orig    = $self->$k;

        if ( $self->constraint_check($k,$v) ) {
            push @changes, "changed field $k from $orig to $v";
            $data{'$set'}->{$k} = $v;
        }
        else {
            $log->error("Value $v does not pass type constraint for $k");
        }
    }
    $data{'$set'}       ->{'updated'} = $now;
    $data{'$addToSet'}  ->{'history'} = {
        who     => $user,
        when    => $now,
        what    => join(', ', @changes),
    };
    my $modhref = {
        collection  => "users",
        match_ref   => { user_id    => $self->user_id },
        data_ref    => \%data,
    };
    return $modhref;
}

 __PACKAGE__->meta->make_immutable;
1;
