package Scot::Roles::Votable;

use Moose::Role;
use namespace::autoclean;

has upvotes     => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_build_empty_vote_array',
    handles     => {
        upvote_count    => 'count',
        add_upvote      => 'push',
        all_upvotes     => 'elements',
        delete_upvote   => 'delete',
        find_upvote     => 'first_index',
        grep_upvotes    => 'grep',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => { 
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'count_upvotes',
    },
);

has downvotes     => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_build_empty_vote_array',
    handles     => {
        downvote_count    => 'count',
        add_downvote      => 'push',
        all_downvotes     => 'elements',
        delete_downvote   => 'delete',
        find_downvote     => 'first_index',
        grep_downvotes    => 'grep',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => { 
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'count_downvotes',
    },
);

sub count_upvotes {
    return shift->upvote_count;
}

sub count_downvotes {
    return shift->downvote_count;
}

sub _build_empty_vote_array {
    return [];
}

sub add_to_votes {
    my $self    = shift;
    my $user    = shift; # who's voting
    my $type    = shift; # up / down
    my $grep    = "grep_".$type."votes";
    my $add     = "add_".$type."vote";

    my @already_voted = $self->$grep( sub { /$user/ } );

    if (scalar(@already_voted) > 0 ) {
        return;
    }
    $self->$add($user);
}

sub pull_from_votes {
    my $self    = shift;
    my $user    = shift;
    my $type    = shift;
    my $find    = "find_".$type."vote";
    my $delete  = "delete_".$type."vote";

    my $index   = $self->$find( sub { /$user/ } );

    if ($index < 0) {
        return;
    }
    $self->$delete($index);
}


1;
