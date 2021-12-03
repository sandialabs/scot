package Scot::Request::Alert;

use strict;
use warnings;
use feature qw(signatures);
use Moose;
no warnings qw(experimental::signatures);
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

extends 'Scot::Request';

has disallowed_update_fields => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub {[qw(
    )]},
);


sub is_valid_create_request ($self) {
    my $json    = $self->json;
    return undef if (! defined $json);

    my $alerts  = $json->{data};
    return undef if (ref($alerts) ne 'ARRAY');
    return undef if (scalar(@$alerts) < 1);
    return 1;
}

sub get_create_href ($self) {
    my $create  = {};
    my $json    = $self->json;
    my $alerts  = $json->{data};

    $create->{subject}      = $json->{subject} // 'unknown';
    $create->{groups}       = $self->build_groups_to_assign();
    $create->{message_id}   = $self->build_message_id($json);
    $create->{columns}      = $self->build_columns($json);
    $create->{tag}          = $json->{tag};
    $create->{source}       = $json->{source};

    return $create;
}

sub get_update_href ($self) {
    my $json    = $self->json;
    my $update  = {};

    foreach my $field (keys %$json) {
        if (! grep {/$field/} @{$self->disallowed_update_fields} ) {
            $update->{$field} = $json->{$field};
        }
    }
    
    return $update;
}

sub build_message_id ($self, $json) {
    my $msgid = $json->{message_id};
    if (defined $msgid) {
        return $msgid;
    }
    # create a probably unique message id
    # based on strigified version of alerts passed it
    return md5_hex(Dumper($json->{data}));
}

sub build_columns ($self, $json) {
    my @columns  = ();
    if ( defined $json->{columns} ) {
        if ( scalar(@{$json->{columns}}) ) {
            return $json->{columns};
        }
    }
    foreach my $key (keys %{$json->{data}->[0]}) {
        push @columns, $key;
    }
    return \@columns;
}

1;


