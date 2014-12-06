package Scot::Model::Checklist;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME
 Scot::Model::Checklist - a moose obj rep of a Scot Checklist

=head1 DESCRIPTION

 Definition of an Checklist

=head2 Consumes Roles

    'Scot::Roles::Ownable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',

=cut

extends 'Scot::Model';
with (  
    'Scot::Roles::Ownable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
);

=head2 Attributes

=over 4

=item C<checklist_id>
 integer identifier
=cut
has checklist_id    => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
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
    default     => 'checklist_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'checklists',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<checklist_subject>

 string containing the subject of the checklist i.e. Phishing

=cut

has checklist_subject    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);


=item C<items>

 string containing the body of the entry

=cut

has items       => (
    is          =>  'rw',
    isa         =>  'HashRef',
    traits      =>  ['Hash'],
    required    =>  0,
    builder     => '_build_empty_items',
    handles     => {
        set_item    => 'set',
        get_item    => 'get',
        item_count  => 'count',
        delete_item => 'delete',
        all_items   => 'kv',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=back

=head2 Methods

=over 4

=cut

sub _build_empty_items {
    return {};
}

=item around BUILDARGS

Custom new method takes the Scot::Controller::Handler and builds a 
checklist from web input.

=cut

around BUILDARGS    => sub {
    my $orig        = shift;
    my $class       = shift;

    if (@_==1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $controller  = $_[0];
        my $user        = $controller->session('user');
        my $req         = $controller->req;
        my $json        = $req->json;
        my $env         = $controller->env;
        my $href        = {env => $env };

        foreach my $i (sort keys %$json) {
            $href->{$i} = $json->{$i};
        }
        $href->{owner}  = $user if (! defined $href->{owner});
        return $class->$orig($href);
    }
    else {
        return $class->$orig(@_);
    }
};

=item C<apply_changes>

take input from the controller and update the object

=cut

sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received " . Dumper($json));

    while ( my ($k, $v) = each %$json ) {
        if ( $k eq "cmd" ) {
            if ( $v eq "additem" ) {
                my $item_href   = $json->{items};
                foreach my $item_index (keys %$item_href) {
                    my $item_value  = $item_href->{$item_index};
                    $self->set_item($item_index => $item_value);
                }
            }
            if ( $v eq  "rmitem" ) {
                my $item_href   = $json->{items};
                $self->delete_item(keys %$item_href);
            }
        }
        else {
            $log->debug("update $k to $v");
            my $orig = $self->$k;
            $self->$k($v);
            unless (ref($v)) {
                push @$changes, "Changed $k from $orig to $v";
            }
            else {
                push @$changes, "Changed $k from ".Dumper($orig). " to ".
                                Dumper($v);
            }
            # probably should check for invalive changes
            # like change in target_id and parent still 
            # pointing to old chain
        }
    }
    $self->updated($now);
    $self->add_historical_record({
        who     => $mojo->session('user'),
        when    => $now,
        what    => $changes,
    });
}

=item C<build_modification_cmd>

modify the the document in the db.  actually, just build the command.

=cut

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
        if ($k eq "cmd") {
            if ( $v eq "additem" ) {
                $data_href->{'$addToSet'}->{items}  = $json->{items};
                push @$changes, "added item";
            }
            if ( $v eq "rmitem" ) {
                $data_href->{'$pullAll'}->{items} = $json->{items};
                push @$changes, "removed item";
            }
        }
        else {
            if ($k eq "items") {
                my $href    = $self->items;
                foreach my $index (keys %$v) {
                    my $update = $v->{$index} // $href->{$index};
                    $data_href->{'$set'}->{"items.$index"} = $update;
                }
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
    }
    $data_href->{'$set'}->{updated} = $now;
    $data_href->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => join(', ', @$changes),
    };
    my $modhref = {
        collection  => "checklists",
        match_ref   => { checklist_id   => $self->checklist_id },
        data_ref    => $data_href,
    };
    return $modhref;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=item L<Scot::Model>

=back

