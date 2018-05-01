package Scot::Controller::Export;

use Data::Dumper;
use Try::Tiny;
use DateTime;
use DateTime::Format::Strptime;
use Mojo::JSON qw(decode_json encode_json);
use Statistics::Descriptive;
use File::Slurp;

use strict;
use warnings;
use base 'Mojolicious::Controller';

=item B<prepexport>

Prepare an HTML verison of the :thing  for serving to the TinyMCE 
editor

=cut

sub prepexport {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("Pre Export");

    try {
        my $thing       = $self->stash('thing');
        my $id          = $self->stash('id') + 0;
        my $collection  = $mongo->collection(ucfirst($thing));
        my $object      = $collection->find_iid($id);
        my $href        = $self->create_export_html($thing, $object);
        $self->stash(export => $href);
        $self->render;
        return;
    }
    catch {
        $log->error("Error preparing export: $_");
        $self->render_error(400, {
            data    => { error_msg => "Prep Export Error: $_" }
        });
    };
}

=item B<sendexport>

Take POSTed HTML and send to provided email address

=cut

sub sendexport {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $req     = $self->req;
    my $json    = $req->json;

    my $html    = $json->{body};
    my $thing   = $json->{thing};
    my $to      = $json->{to};

    foreach my $addr (@$to) {
        $self->mail_to_user($addr, $html, $thing);
    }
    $self->do_render({
        status  => "email sent"
    });
}

sub mail_to_user {
    my $self    = shift;
    my $user    = shift;
    my $html    = shift;
    my $col     = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;

    my $addr    = $user;
    my $subject = "SCOT Export of $col - $id";
    my $msg = Mail::Send->new(Subject => $subject, To => $addr);
    $msg->set('Content-Type',"text/html");
    my $fh  = $msg->open;
    print $fh $html;
    $fh->close;
}

sub create_export_html {
    my $self    = shift;
    my $thing   = shift;
    my $object  = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $href    = $object->as_hash;
    $href->{export_type} = ucfirst($thing);
    $href->{entities}    = $self->build_entity_export($object->id, $thing);
    $href->{created}     = $self->stringify_epoch($href->{created});
    $href->{updated}     = $self->stringify_epoch($href->{updated});

    if ( $object->meta->does_role("Scot::Role::Entriable") ) {
        $href->{entries}     = $self->build_entry_export($object->id, $thing);
    }

    if ( $object->meta->does_role("Scot::Role::Tags") ) {
        $href->{tags}   = $self->build_tag_export($object->id, $thing);
    }

    $log->debug("export data is ",{filter=>\&Dumper,value=>$href});

    return $href;
}

sub stringify_epoch {
    my $self    = shift;
    my $epoch   = shift;
    my $dt      = DateTime->from_epoch(epoch => $epoch);
    return $dt->ymd." ".$dt->hms;
}

sub build_tag_export {
    my $self    = shift;
    my $id      = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my @appearances = map { $_->{apid} } 
        $mongo->collection('Appearance')->find({
            type            => 'tag',
            'target.type'   => $col,
            'target.id'     => $id,
        })->all;
    my @tags = map { $_->{value} } $mongo->collection('Tag')
                     ->find({ id => {'$in' => \@appearances}})->all;
    return wantarray ? @tags : \@tags;
}


sub build_entity_export {
    my $self    = shift;
    my $id      = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my @results = ();

    my $cursor  = $mongo->collection('Link')
                  ->get_linked_objects_cursor({
                        id  => $id, type => $col 
                    }, "entity");

    while ( my $entity = $cursor->next ) {
        my $record  = {
            value       => $entity->value,
            type        => $entity->type,
            location    => $entity->location,
        };
        my $entrycur    = $mongo->collection('Entry')
                          ->get_entries_by_target({
                            id => $entity->id, type => "entity"
                          });

        while ( my $entry = $entrycur->next ) {
            push @{$record->{entry}}, $entry->body_plain;
        }
        push @results, $record;
    }
    return wantarray ? @results : \@results;
}

sub build_entry_export {
    my $self    = shift;
    my $id      = shift;
    my $col     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $mygroups    = $self->get_groups;
    my $user        = $self->session('user');
    my @summaries   = ();
    my $cursor = $mongo->collection('Entry')->get_entries_by_target({
                    id      => $id,
                    type    => $col
                    });

    $cursor->sort({id => 1});
    
    return $self->thread_entries($cursor);

}

sub thread_entries {
    my $self    = shift;
    my $cursor  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mygroups    = $self->get_groups;
    my $user        = $self->session('user');

    $log->debug("Threading ". $cursor->count . " entries...");
    $log->debug("users groups are: ", {filter=>\&Dumper, value=>$mygroups});

    my @threaded    = ();
    my %where       = ();
    my $rindex      = 0;
    my $sindex      = 0;
    my $count       = 1;
    my @summaries   = ();

    $cursor->sort({id => 1});

    ENTRY:
    while ( my $entry   = $cursor->next ) {

        # do not thread (include) entries not viewable by user
        unless ( $entry->is_readable($mygroups) ) {
            $log->debug("Entry ".$entry->id." is not readable by $user");
            next ENTRY;
        }

        $count++;
        my $href            = $entry->as_hash;
        if ( ! defined $href->{children} ) {
            $href->{children}   = [];   # create holder for children
        }

        if ( ref($href->{children}) ne "ARRAY" ) {
            $href->{children}   = [];   # create holder for children
        }

        if ( $entry->class eq "summary" ) {
            $log->trace("entry is summary");
            push @summaries, $href;
            $where{$entry->id} = \$summaries[$sindex];
            $sindex++;
            next ENTRY;
        }

        if ( $href->{body} =~ /class=\"fileinfo\"/ ) {
            # we have a file entry so we need to "enrich" the data
            # so that the UI can build sendto buttons
            # actions defined in the config file
            if ( defined $self->env->{entry_actions}->{fileinfo} ) {
                my $action  = $env->{entry_actions}->{fileinfo};
                my $servername = `hostname`;
                chomp($servername);
                $log->debug("SERVERNAME is $servername");
                $href->{actions} = [ $action->($href,$servername) ];
            }
        }

        if ( $entry->parent == 0 ) {
            # add this href to threaded array
            $threaded[$rindex]  = $href;
            # store a link to this entry based on the entry id
            $where{$entry->id}  = \$threaded[$rindex];
            # incr the index
            $rindex++;
            next ENTRY;
        }

        $log->debug("Entry ".$entry->id." is a child entry to ".$entry->parent);

        # get the parent href
        my $parent_ref          = $where{$entry->parent};
        # get the array ref within the parent
        my $parent_kids_aref    = $$parent_ref->{children};
        $log->trace("parents children: ",{filter=>\&Dumper, value => $parent_kids_aref});
        my $child_count         = 0;

        if ( defined $parent_kids_aref ) {
            $child_count    = scalar(@{$parent_kids_aref});
            $log->debug("Parent has $child_count children");
        }

        my $new_child_index = $child_count;
        $log->debug("The parent has $child_count children");
        $parent_kids_aref->[$new_child_index]  = $href;
        $log->debug("added entry to parents aref");
        $log->debug("parents children: ",{filter=>\&Dumper, value => $parent_kids_aref});
        $where{$entry->id} = \$parent_kids_aref->[$new_child_index];
    }

    unshift @threaded, @summaries;

    $log->debug("ready to return threaded entries");

    return wantarray ? @threaded : \@threaded;
}
sub render_error {
    my $self    = shift;
    my $code    = shift;
    my $href    = shift;
    $self->render(
        status  => $code,
        json    => $href,
    );
}
sub get_groups {
    my $self    = shift;
    my $aref    = $self->session('groups');
    my @groups  = map { lc($_) } @{$aref};
    return wantarray ? @groups : \@groups;
}

1;
