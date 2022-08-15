package Scot::Request;

use feature qw(signatures);
use Moose;
use strict;
use warnings;
no warnings qw(experimental::signatures);
use Data::Dumper;
use Module::Runtime qw(require_module);
use Array::Utils qw(:all);
use lib '../../../lib';
use Scot::Mquery;

has controller  => (
    is          => 'ro',
    isa         => 'Mojolicious::Controller',
    required    => 1,
);

has mqm => (
    is          => 'ro',
    isa         => 'Scot::Mquery',
    required    => 1,
    builder     => '_build_mqm',
);

sub _build_mqm ($self) {
    return Scot::Mquery->new();
}

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has id          => (
    is          => 'ro',
    isa         => 'Int',
    required    => 0,
);

has subcollection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 0,
);

has subid       => (
    is          => 'ro',
    isa         => 'Int',
    required    => 0,
);

has user        => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has groups      => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
);

has ipaddr      => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has params      => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {{}},
);

has json        => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {{}},
);

around BUILDARGS => sub {
    my $orig        = shift;
    my $class       = shift;

    if ( @_ == 1 and ref($_[0]) eq 'Scot::Controller::Api2' ) {
        my $c       = $_[0];
        my $req     = $c->req;
        my $json    = $req->json // {};
        my $params  = $req->params->to_hash // {};
        my $user    = $c->session('user') // 'unknown';
        my $groups  = $c->session('groups') // [];
        my $collection  = $c->stash('thing');
        my $id          = $c->stash('id') + 0;
        my $subthing    = $c->stash('subthing') // '';
        my $subid       = (defined $c->stash('subid')) ? $c->stash('subid')+0 : 0;
        my %args    = (
            params          => $params,
            json            => $json,
            collection      => $collection,
            id              => $id,
            subcollection   => $subthing,
            subid           => $subid,
            user            => $user,
            groups          => $groups,
            ipaddr          => $c->tx->remote_address,
            controller      => $c,
        );
        return $class->$orig(\%args);
    }
    else {
        # not passed the controller so do default Moose build
        return $class->$orig(@_);
    }
};

sub as_hash ($self) {
    my $href    = {
        params      => $self->params,
        json        => $self->json,
        collection  => $self->collection,
        id          => $self->id,
        subcollection => $self->subcollection,
        subid         => $self->subid,
        user          => $self->user,
        groups        => $self->groups,
    };
    return $href;
}

sub get_list_params ($self) {
    my $query   = $self->build_query();
    my $options = $self->get_options();
    return $query, $options;
}

sub get_delete_href ($self) {
}

sub build_query ($self) {
    my $match                   = $self->mqm->build_match_ref($self->params);  
    # the requestors groups    
    my $reqgroups               = $self->groups;     
    # only allow them to see what they are allowed to read
    $match->{'groups.read'}     = $reqgroups->{read};
    return $match;
}

sub get_options ($self) {
    my $options = {};
    $options->{sort}    = $self->get_sort(); # array [ field1, dir1, field2, dir2 ]
    $options->{limit}   = $self->get_limit();# int
    $options->{skip}    = $self->get_skip(); # int
    return $options;
}

sub get_sort ($self) {
    my @final   = ();
    # sort comes in as a array of params like: &sort=-id&sort=+when
    my $param_sort = $self->params->{sort};
    if ( defined $param_sort ) {
        if ( ! ref($param_sort) ) {
            $param_sort = [$param_sort];
        }
        foreach my $term (@$param_sort) {
            if ( $term =~ /^\-(\S+)$/ ) {
                push @final, $1, -1;
            }
            elsif( $term =~ /^\+(\S+)$/ ) {
                push @final, $1, 1;
            }
            else {
                push @final, $1, 1;
            }
        }
        return \@final;
    }

    # sort comes in as a json object like: { id: -1, when: 1 }
    my $json_sort   = $self->json->{sort};
    if ( defined $json_sort ) {
        return $json_sort;
    }
    return $self->defaults->{sort}; # { id => -1 }, usually
}

sub get_limit ($self) {
    if ( defined $self->params->{limit} ) {
        return $self->params->{limit};
    }
    if ( defined $self->json->{limit} ) {
        return $self->json->{limit};
    }
    return $self->defaults->{default_limit};
}

sub get_skip ($self) {
    if ( defined $self->params->{skip} ) {
        return $self->params->{skip};
    }
    if ( defined $self->json->{skip} ) {
        return $self->json->{skip};
    }
    return 0;
}

sub build_groups_to_assign ($self) {
    my $json    = $self->json;
    my $ugroups = $self->groups;
    my $perms   = {};

    if ( ! defined $json->{groups} ) {
        if ( defined $ugroups ) {
            return {
                read    => $ugroups,
                modify  => $ugroups,
            };
        }
        return { 
            read    => [qw(wg-scot-admin)],
            modify  => [qw(wg-scot-admin)],
        };
    }

    my @read;
    my @modify;

    if ( ! grep { /wg-scot-admin/ } @$ugroups ) {
        # a user can only set the group permissions to what they are 
        # a member of.
        @read    = (defined $json->{groups}->{read}) ?
            intersect(@$ugroups, @{$json->{groups}->{read}}) :
            @$ugroups;
        @modify  = (defined $json->{groups}->{modify}) ?
            intersect(@$ugroups, @{$json->{groups}->{modify}}) :
            @$ugroups;
    }
    else {
        # the superuser can set it to anything though
        @read   = (defined $json->{grops}->{read}) ?
            @{$json->{gropus}->{read}} :
            @$ugroups;
        @read   = (defined $json->{grops}->{read}) ?
            @{$json->{gropus}->{read}} :
            @$ugroups;
    }

    @read   = map { lc($_) } @read;
    @modify = map { lc($_) } @modify;

    return {
        read    => \@read,
        modify  => \@modify,
    };
}


sub get_related_domain ($self, $name) {
    my $class = "Scot::Domain::".ucfirst($name);
    require_module($class);
    return $class->new({mongo => $self->mongo});
}


1;




