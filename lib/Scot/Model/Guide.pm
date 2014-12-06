package Scot::Model::Guide;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME
 Scot::Model::Guide - a moose obj rep of a Scot Guide

=head1 DESCRIPTION
    A Guide is a tied to an alert_type and allows analysts to enter guides on 
    how to 
    respond to an alert
=cut

extends 'Scot::Model';


=head2 Attributes

=cut
with (  
    'Scot::Roles::Loggable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Historable',
    'Scot::Roles::Entriable',
);

has guide_id   => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<idfield>
 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...
=cut
has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'guide_id',
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
    default     => 'guides',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<guide>
 link to an alert type -> a guide for this type of alert
=cut
has guide  => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'unspecified',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


=item custom new
    if you pass a Mojo::Message::Requst in as only parameter
        parse it and then do normal moose instantiation
=cut
around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;
        my $href    = {
            guide   => $json->{'guide'},
            env     => $_[0]->env,
        };
        my $rg = $json->{'readgroups'};
        my $mg = $json->{'modifygroups'};

        if (scalar(@$rg) > 0) {
            $href->{readgroups} = $rg;
        }

        if (scalar(@$mg) > 0 ) {
            $href->{modifygroups} = $mg;
        }

        return $class->$orig($href);
    }
    # pulls from db will be a hash ref
    # which moose will handle normally
    else {
        return $class->$orig(@_);
    }
};

#sub BUILD {
#    my $self    = shift;
#    my $log     = $self->log;
#    $log->debug("BUILT GUIDE OBJ");
#}

sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received ".Dumper($json));

    while ( my ($k,$v) =  each %$json ) {
        if ($k eq "cmd") {
            $log->debug("command encounterd, but not expected");
        } 
        else {
            my $orig    = $self->$k;
            $self->$k($v);
            push @$changes, "Changed $k from $orig to $v";
        }
    }
    $self->updated($now);
    $self->add_historical_record({
        who     => $mojo->session('user'),
        when    => $now,
        what    => $changes,
    });
}

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data_href   = {};

    while ( my ($k, $v) = each %$json ) {
        if ( $k eq "cmd" ) {
            $log->error("command encountered but not expected");
        }
        else {
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, "updated $k from $orig";
                $data_href->{'$set'}->{$k} = $v;
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data_href->{'$set'}->{updated} = $now;
    $data_href->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => join(', ', @$changes),
    };
    my $modhref = {
        collection  => "guides",
        match_ref   => { guide_id  => $self->guide_id },
        data_ref    => $data_href,
    };
    return $modhref;
}

 __PACKAGE__->meta->make_immutable;
1;
