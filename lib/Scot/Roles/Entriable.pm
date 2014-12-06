package Scot::Roles::Entriable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

requires 'log';

=head1 Name

Scot::Roles::Entriable

=head1 Description

This role confers the ability to attach "Entries" to the consuming object

=head1 Attributes

=over 4

=item C<summary_entry_id>

This holds the entry_id of the entry that will be displayed at the top
as the summary for the alert, event, etc. 

=cut



has 'summary_entry_id'  => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=back

=head1 Methods

=over 4

=item C<entry_count>

return the number of entries attached to this object.  must pass it
a reference to the Scot::Util::Mongo object.

=cut

sub entry_count {
    my $self        = shift;
    my $mongo       = shift;
    my $log         = $self->log;

    my $myref           = ref($self);
    (my $target_type    = $myref) =~ s/Scot::Model::(.*)/$1/;
    $target_type        = lc($target_type);

    my $idfield     = $self->idfield;
    my $target_id   = $self->$idfield;

    my $href    = {
        collection  => "entries",
        match_ref   => {
            target_type     => $target_type,
            target_id       => $target_id,
        }
    };

    $log->debug("href in entry count: ".Dumper($href));
    
    return $mongo->count_matching_documents($href);
}

=item C<get_entries>

retrieve the entries for this thing from the entries collection

=cut

sub get_entries {
    my $self        = shift;
    my $groups_aref = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;

    my $idfield         = $self->idfield;
    my $target_id       = $self->$idfield;
    (my $target_type    = ref($self) ) =~ s/Scot::Model::(.*)/$1/;
    $target_type        = lc($target_type);

    $log->debug("Retrieving entries for $target_type $target_id");

    my $match_ref;

    if ( $target_type eq "alertgroup" ) {
        $match_ref  = { 
            'readgroups'    => { '$in' => $groups_aref },
            target_type     => "alert",
            target_id       => { '$in' =>  $self->alert_ids },
        };
    }
    else {
        $match_ref   = {
                'readgroups'    => { '$in' => $groups_aref },
                target_type     => $target_type,
                target_id       => $target_id,
        };
    }

    $log->debug("match_ref is ".Dumper($match_ref));

    my $cursor      = $mongo->read_documents({
        collection  => "entries",
        match_ref   => $match_ref,
        sort_ref    => { entry_id => 1},
    });

    return $self->thread_entries($cursor);
}

=item C<thread_entries>

takes a cursor of entries and returns an aref of threaded entries.

=cut

sub thread_entries {
    my $self        = shift;
    my $cursor      = shift;
    my @threaded    = ();
    my %where       = ();
    my $rindex      = 0;
    my $log         = $self->log;

    my $start = clock_gettime(CLOCK_MONOTONIC);
    $log->debug("starting threading of entries");

    my $count = 1;
    my $tz      = $self->timezone();

    while ( my $entry_href  = $cursor->next_raw ) {
        # reduce data sent, its already in body_flaired
        delete $entry_href->{body}; 
        delete $entry_href->{body_plain}; # ditto;

        $count ++;
        $entry_href->{children} = [];

        my $parent_id   = $entry_href->{parent} // 0;
        my $entry_id    = $entry_href->{entry_id};

        if ( $parent_id == 0 ) {
            $threaded[$rindex]  = $entry_href;
            $where{$entry_id}   = \$threaded[$rindex];
            $rindex++;
        }
        else {
            my $parent_ref          = $where{$parent_id};
            my $parent_kids_aref    = $$parent_ref->{children};
            my $child_count         = 0;

            if ( defined $parent_kids_aref ) {
                $child_count        = scalar( @{$parent_kids_aref} );
            }
            my $new_child_index = $child_count;
            $parent_kids_aref->[$new_child_index]   = $entry_href;
            $where{$entry_id}   = \$parent_kids_aref->[$new_child_index];
        }
    }

    my @results   = ();
    for(my $i=0; $i<$rindex; $i++) {
      push @results, $threaded[$i];
    }
    my $end   = clock_gettime(CLOCK_MONOTONIC);
    my $secs  = $end - $start;

    $log->debug("threading took $secs seconds for ".$count." entries");
    return \@threaded;
}

=item C<add_entry>

Add an entry 

=cut 

sub add_entry {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $env     = $self->env;
    my $mongo   = $env->mongo;


    my $mytype  = ref($self);
    (my $target = $mytype) =~ s/Scot::Model::(.*)/$1/;
    $target     = lcfirst($target);
    my $idfield = $self->idfield;
    my $id      = $self->$idfield;

    $log->debug("Adding Entry to $target $id" );

    $href->{target_type}    = $target;
    $href->{target_id}      = $id;
    $href->{env}            = $env;
    $href->{log}            = $log;

    # $log->debug("entry href is ".Dumper($href));

    my $entry_obj   = Scot::Model::Entry->new($href);
    my $entry_id    = $mongo->create_document($entry_obj);
    $entry_obj->entry_id($entry_id);
    $env->activemq->send("activity",{
        action  => "create",
        type    => "entry",
        id      => $entry_id,
    });
}



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
