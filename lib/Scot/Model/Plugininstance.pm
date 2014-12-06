package Scot::Model::Plugininstance;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME
 Scot::Model::Plugininstance - a moose obj rep of a Scot Plugin that has been invoked

=head1 DESCRIPTION
   An instance of a plugin for SCOT.  This code writes/reads instances of a plugin from the database, runs it, gets results and cleans up 
=cut

extends 'Scot::Model';


=head2 Attributes

=cut
with (  
    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
);


=item C<plugin_id>
 Which plugin has been requested to run.
=cut
has plugin_id   => (
    is          => 'rw',
    isa         => 'Int',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<instance_id>
 Unique identifier for each plugin invoked
=cut
has plugininstance_id   => (
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
    default     => 'plugininstance_id',
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
    default     => 'plugininstance',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);


=item C<results>
 If this is the plugin result.
=cut
has results  => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<status>
 If this is a "simple", or "advanced" style plugin.
=cut
has status  => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'new',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<requester>
  The username of the person who requested this plugin be run.  
  This is checked against the plugin run metagroup to see
  if the user can even run this plugin.
=cut
has requester   => (
    is          => 'rw',
    isa         => 'Str',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


=item C<target_type>
  What type ( event, alert, or incident) this was invoked from.
=cut
has target_type   => (
    is          => 'rw',
    isa         => 'Str',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


=item C<target_id>
  The ID fo the (event, alert, or incident) this was invoked from.
=cut
has target_id   => (
    is          => 'rw',
    isa         => 'Int',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<parent>
 Which entry or alert, or other this was invoked from.
=cut
has parent   => (
    is          => 'rw',
    isa         => 'Int',
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


=item C<entry_id>
 Entry id this was created to hold results.
=cut
has entry_id   => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


=item C<value>
 The value that the user clicked on to invoke this plugin i.e. 192.168.0.1 or www.google.com or nrpeter@sandia.gov
=cut
has value  => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<type>
 The type of value that the user clicked on to invoke this plugin i.e. ipaddr, email, file, etc.
=cut
has type  => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<options>
 JSON document describing the options (if any) the user selected when invoking this plugin
=cut
has options => (
     is       =>'rw',
     isa      =>'Any',
     default  => '',
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
        my $user    = $_[0]->session('user');
        my $json    = $req->json;
        my $href    = {
            options  => $json->{'options'},
            value    => $json->{'value'},
            type    => $json->{'type'},
            plugin_id => $json->{'plugin_id'},
            target_id => $json->{'target_id'},
            target_type => $json->{'target_type'},
            parent      => $json->{'parent'},
            requester   => $user,
            env       => $_[0]->env,
        };


        return $class->$orig($href);
    }
    # pulls from db will be a hash ref
    # which moose will handle normally
    else {
        return $class->$orig(@_);
    }
};

sub _build_empty_array {
    return [];
}

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
        } elsif ($k eq "requester") {
            #do nothing, the user should not be able to set this
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
    $data_href->{'$set'}->{requester} = $user;
    $data_href->{'$set'}->{updated} = $now;
    $data_href->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => join(', ', @$changes),
    };
    my $modhref = {
        collection  => "plugins",
        match_ref   => { plugin_id  => $self->plugin_id },
        data_ref    => $data_href,
    };
    return $modhref;
}

 __PACKAGE__->meta->make_immutable;
1;
