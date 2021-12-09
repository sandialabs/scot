package Scot::Request::Entry;

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
        created
    )]},
);


sub is_valid_create_request ($self) {
    my $json    = $self->json;
    return undef if (! defined $json);
    
    return undef if (! defined $json->{body});
    return undef if (! defined $json->{target_id});
    return undef if (! defined $json->{target_type});
    return 1;
}

sub get_create_href ($self) {
    my %create  = ();
    my $json    = $self->json;

    $create{groups} = $self->build_groups_to_assign();
    $create{owner}  = $self->user;
    $create{tlp}    = $self->build_tlp();
    $create{target} = { type => $json->{target_type}, id => $json->{target_id} };

    if ( my $task = $self->extract_task ) {
        $create{class}  = "task";
        $create{metadata}   = { task => $task };
    }

    if ( defined $json->{class} && $json->{class} eq "json" ) {
        # temporary: create html versio of json.  
        # future: UI will handle
        # $json->{body} = $self->create_json_html($json->{metadata});
    }

    return wantarray ? %create : \%create;
}

sub get_update_href ($self) {
    my $json    = $self->json;
    my $update  = {};

    foreach my $field (keys %$json) {
        if (! grep {/^$field$/} @{$self->disallowed_update_fields} ) {
            $update->{$field} = $json->{$field};
        }
    }
    return $update;
}

sub build_tlp ($self) {
    my $json    = $self->json;
    if ( defined $json->{tlp} ) {
        return $json->{tlp};
    }
    return 'unset';
}

sub extract_task ($self) {
    my %task    = ();
    my $json    = $self->json->{task};

    return undef if (! defined $json);

    $task{when} = time()        unless defined $json->{when};
    $task{who}  = $self->user   unless defined $json->{who};
    $task{status} = "open"      unless defined $json->{status};

    return wantarray ? %task : \%task;
}

1;


