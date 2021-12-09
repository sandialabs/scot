package Scot::Domain::Entry;

use strict;
use warnings;
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Entry');
}

# to create an alert, you must provide an alertgroup
# to attach the alert to.
sub create ($self, $request) {
    if ( ! $request->is_valid_create_request ) {
        die "Invalid Create Request Data";
    }

    my $create_href = $request->get_create_href;
    my $entry       = $self->collection->create($create_href);
    my $ehref       = $entry->as_hash;
    return $ehref;
}

sub process_create_result ($self, $result, $request) {
    my $return  = {
        code    => 200,
        json    => {
            id      => $result->{id},
            action  => 'post',
            thing   => 'entry',
            status  => 'ok',
        }
    };
    return $return;
}

sub find_related ($self, $type, $id) {
    if ($type eq "Alertgroup") {
        return $self->get_threaded();
    }
}

sub get_threaded ($self, $request, $target) {
    my @threaded    = ();
    my $user            = $request->user;
    my $users_groups    = $request->groups;

    my %where   = ();
    my $rindex  = 0;
    my $sindex  = 0;
    my $count   = 1;
    my @summaries   = ();

    my $cursor  = $self->collection->find({
        'target.type'   => $target->{type},
        'target.id'     => $target->{id},
    });

    $cursor->sort({id=>1});

    ENTRY:
    while ( my $entry = $cursor->next ) {

        next ENTRY if ( ! $entry->is_readable($users_groups) ); 

        $count++;
        my $href    = $entry->as_hash;
        
        if (! defined $href->{children} or ref($href->{children}) ne "ARRAY") {
            $href->{children} = [];
        }

        if ($entry->class eq "summary") {
            push @summaries, $href;
            $where{$entry->id} = \$summaries[$sindex];
            $sindex++;
            next ENTRY;
        }

        # removed fileinfo action code, because not used

        if ($entry->parent == 0) {
            $threaded[$rindex] = $href;
            $where{$entry->id} = \$threaded[$rindex];
            $rindex++;
            next ENTRY;
        }

        my $parent_ref       = $where{$entry->parent};
        my $parents_children = $$parent_ref->{children};
        my $child_count      = 0;

        if ( defined $parents_children ) {
            $child_count    = scalar(@{$parents_children});
        }

        my $new_sibling_index   = $child_count;
        $parents_children->[$new_sibling_index] = $href;
        $where{$entry->id} = \$parents_children->[$new_sibling_index];
    }
    unshift @threaded, @summaries;
    return wantarray ? @threaded : \@threaded;
}

1;
