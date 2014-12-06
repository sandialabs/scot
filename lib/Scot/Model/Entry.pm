package Scot::Model::Entry;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Redis;
use Socket;
use Data::Dumper;
use HTML::Entities;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Entry - a moose obj rep of a Scot Entry

=head1 DESCRIPTION

 Definition of an Entry

=cut

extends 'Scot::Model';

=head2 Enumerations

 valid_status : open, assigned, completed, closed

=cut

enum 'valid_status', [qw(open assigned completed closed)];

=head2 Consumes Roles

    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Plaintextable',
    'Scot::Roles::Ownable',
#    'Scot::Roles::Scot2identifiable',
    'Scot::Roles::Targetable',
    'Scot::Roles::Whenable',
    'Scot::Roles::Searchable'
=cut

with (  
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Plaintextable',
    'Scot::Roles::Ownable',
#    'Scot::Roles::Scot2identifiable',
    'Scot::Roles::Targetable',
    'Scot::Roles::Whenable',
    'Scot::Roles::Searchable'
);

=head2 Attributes

=over 4

=item C<entry_id>

 the integer id of the entry

=cut

has entry_id    => (
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

easy way to find entry_id above

=cut

has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'entry_id',
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
    default     => 'entries',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<task>

 this field holds a hash of 
 {
    when    => sec since epoch of last update to the status below
    who     => the username of who the task is assigned to 
    status  => open|assigned|completed
 }

=cut

has task        => (
    is          => 'rw',
    isa         => 'HashRef',
    traits      => ['Hash'],
    required    => 0,
    default     => sub { {} },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<is_task>

Boolean that lets you know if this is a task

=cut 

has is_task     => (
    is          => 'rw',
    isa         => 'Bool',
    traits      => ['Bool'],
    required    => 1,
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<sanitize>

Boolean. Set this to true if you want the Entry to have a HTML entities
sanitization pass.  (change <script> to &lt;script&gt;)

=cut
    
has sanitize    => (
    is          => 'rw',
    isa         => 'Bool',
    traits      => ['Bool'],
    required    => 1,
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);
    

=item C<parent>

    the oid of the parent entry

=cut

has parent    => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<body>

 string containing the body of the entry

=cut

has body        => (
    is          =>  'rw',
    isa         =>  'Maybe[Str]',
    required    =>  1,
    default     => ' ',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<body_flaired>

 string containing the flaired version of the body

=cut

has body_flaired    => (
    is          =>  'rw',
    isa         =>  'Maybe[Str]',
    required    =>  0,
    default     => ' ',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<body_plaintext>

 string containing the plaintext version of the body

=cut

has body_plaintext    => (
    is          =>  'rw',
    isa         =>  'Maybe[Str]',
    required    =>  0,
    default     => ' ',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=back

=head2 Methods

=over 4

=item around body

not doing anything now, acts a setter/getter.

=cut

around body => sub {
    my $orig    = shift;
    my $self    = shift;

    # the getter was called
    return $self->$orig() unless @_;
    
    # we are updating body, there for push updates to 
    # body_flaired and body_plaintext

    my $raw = shift;
    $self->$orig($raw);
    # try doing this here to prevent duplication of this processing
    $self->update_data_derrived_from_body;
    return 1;
};

=item around body_flaired

checks to see if body_flaired is null 
and if so, populates body_flaired based on body's contents

=cut

around body_flaired => sub {
    my $orig        = shift;
    my $self        = shift;

    if ( @_ ) {
        $self->$orig(@_);
        return 1;
    }
    my $bf  = $self->$orig();
    if ( $bf eq '' or $bf eq ' ' or ! defined $bf ) {
        # get flair
        $self->update_data_derrived_from_body;
    }
    return $self->$orig();
};

=item get_snippets

  Turn string into array of n-grams of length 4

=cut
sub get_snippets {
  my $self = shift;
  my $text = lc(shift // '');

  my $seen = {};
  for(my $i=0; $i<length($text); $i++) {
    my $snippet = substr $text, $i, 4;
    $seen->{$snippet} = 1;
  }
  return $seen;
}

=item update_data_derrived_from_body

submit body to phantomjs for "flairing"
get results and set attributes body_flaired, body_plaintext
adds self to entities records

=cut

sub update_data_derrived_from_body_phantom {
    my $self        = shift;
    my $orig_text   = shift;
    my $env         = $self->env;
    my $log         = $self->log;
    my $phantom     = $env->phantom;
    my $redis       = $env->redis;

    $log->debug("update_data_derrived_from_body");

    my ($flair, 
        $plain, 
        $entities_aref) = $phantom->submit($self->body);

    $self->body_flaired($flair);
    $self->body_plaintext($plain);

    $log->debug("found entities: ", {
        filter=> \&Dumper, value => $entities_aref});

    if ( scalar(@$entities_aref) > 0 ) {
        $self->add_self_to_entities($entities_aref);
    }
    else {
        $log->debug("NO ENTITIES FOUND!");
    }

    my $orig_snippets = $self->get_snippets($orig_text);
    my $new_snippets  = $self->get_snippets($plain);

    $log->trace('origional_snippets'.Dumper($orig_snippets));
    $log->trace('New_snippets'.Dumper($new_snippets));

    $redis->update_search_db($self->entry_id, $orig_snippets, $new_snippets);
}

=item update_data_derrived_from_body 

submit body to EntityExtractor.pm

=cut

sub update_data_derrived_from_body {
    my $self        = shift;
    my $orig_text   = shift;
    my $env         = $self->env;
    my $log         = $self->log;
    my $extractor   = $env->entity_extractor;
    my $redis       = $env->redis;

    $log->debug("update_data_derrived_from_body");

    my $extract_href = $extractor->process_html($self->body);
    my $flair        = $extract_href->{flair};
    my $plain        = $extract_href->{text};
    my $entities_aref = $extract_href->{entities};

    $self->body_flaired($flair);
    $self->body_plaintext($plain);

    $log->trace(Dumper($entities_aref));

    if ( scalar(@$entities_aref) > 0 ) {
        $self->add_self_to_entities($entities_aref);
    }

    my $orig_snippets = $self->get_snippets($orig_text);
    my $new_snippets  = $self->get_snippets($plain);

    $log->trace('origional_snippets'.Dumper($orig_snippets));
    $log->trace('New_snippets'.Dumper($new_snippets));

    $redis->update_search_db($self->entry_id, $orig_snippets, $new_snippets);
}




=item 

sub update_data_derrived_from_body {
    my $self        = shift;
    my $orig_text   = shift;
    my $controller  = $self->controller;
    my $log         = $self->log;
    my $app         = $controller->app;
    my $phantom     = $app->phantomjs;

    $log->debug("update_data_derrived_from_body");

    my ($flair, 
        $plain, 
        $entities_aref) = $phantom->submit($self->body);

    $self->body_flaired($flair);
    $self->body_plaintext($plain);

    $log->trace(Dumper($entities_aref));

    if ( scalar(@$entities_aref) > 0 ) {
        $self->add_self_to_entities($entities_aref);
    }

    my $orig_snippets = $self->get_snippets($orig_text);
    my $new_snippets  = $self->get_snippets($plain);

    $log->trace('origional_snippets'.Dumper($orig_snippets));
    $log->trace('New_snippets'.Dumper($new_snippets));

    my @add =   ();
    my @del =   ();
    my $id = $self->entry_id;

    my $redis = Redis->new;
    foreach my $key ( keys %{$new_snippets} ) {
        if (!defined($orig_snippets->{$key})) {
            $log->trace('sadd e'.$key.' '.$id);
            $redis->sadd('e'.$key, $id);
        }
    }

    foreach my $key ( keys %{$orig_snippets} ) {
        if (!defined($new_snippets->{$key})) {
            $log->trace('srem e'.$key.' '.$id);
            $redis->srem('e'.$key, $id);
        }
    }
}

=cut

=item around body_flaired

checks to see if body_flaired is null 
and if so, populates body_flaired based on body's contents

=cut

around body_plaintext => sub {
    my $orig        = shift;
    my $self        = shift;

    if ( @_ ) {
        $self->$orig(@_);
        return 1;
    }

    my $bf  = $self->$orig();
    if ( $bf eq '' or $bf eq ' ' or ! defined $bf ) {
        # get flair
        $self->update_data_derrived_from_body;
    }
    return $self->$orig();
};

sub _empty_hash {
    return [];
}

=item around BUILDARGS

build the object from the input stored in the controller

=cut

around BUILDARGS    => sub {
    my $orig        = shift;
    my $class       = shift;

    if (@_==1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $controller  = $_[0];
        my $req         = $controller->req;
        my $user        = $controller->session('user');
        my $json        = $req->json;

        my $text        = $json->{'body'};
        my $id          = $class->numberfy($json->{'target_id'});
        my $target      = $json->{'target_type'};
        my $parent      = $class->numberfy($json->{'parent'});
        my $task        = $class->numberfy($json->{'is_task'});
        my $sanitize    = $json->{'sanitize'};
        my $status      = $json->{'status'};
        my $env         = $controller->env;
        my $log         = $env->log;

#        $log->debug("in BUILDARGS for entry!");

        if ( defined $sanitize and $sanitize eq "1" )  {
            $text   = encode_entities($text);
        }

        my $href        = { 
            'log'           => $log,
            body            => $text,
            target_id       => $id,
            target_type     => $target,
            parent          => $parent,
            status          => $status,
            owner           => $user,
            sanitize        => $sanitize,
            env             => $env,
        };
        if ($task) {
            $href->{is_task}    = 1;
            $href->{task}       = {
                when    =>  time(),
                who     =>  $json->{"assignee"} // $user,
                status  =>  $json->{"status"}   // "open",
            };
        }

        my $rg  = $json->{'readgroups'};
        my $mg  = $json->{'modifygroups'};
        $href->{readgroups}   = $rg if ( scalar(@$rg) > 0 );
        $href->{modifygroups} = $mg if ( scalar(@$mg) > 0 );
        return $class->$orig($href);
    }
    else {
        return $class->$orig(@_);
    }
};

=item C<apply_changes>

apply changes from web request directly to object
remember to save the object back to the db if you want
the changes to persist

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
        if ( $k eq "is_task" ) {
            $log->debug("making entry a task...");
            $self->task({
                when    =>  time(),
                who     =>  $json->{"assignee"} // $user,
                status  =>  $json->{"status"} // "open",
            });
            $self->is_task($v);
            push @$changes, "made entry a task";
        }
        elsif ( $k eq "assignee" ) {
            $log->debug("assigning a task to $v");
            my $href    = $self->task;
            $href->{who} = $v;
            $self->task($href);
            $self->is_task(1);
            push @$changes, "assigned task to $v";
        }
        elsif ( $k eq "status" ) {
            $log->debug("changing status of task to $v");
            my $href    = $self->task;
            my $orig    = $href->{status};
            $href->{status} = $v;
            $self->task($href);
            $self->is_task(1);
            push @$changes, "Changed $k from $orig to $v";
        }
        elsif ( $k eq "maketask" ) {
            $self->is_task(1);
            $self->task({
                when    => $now,
                who     => $json->{assignee} // $user,
                status  => $json->{taskstatus} // "open",
            });
            push @$changes, "make entry a task";
        }
# do something like this to handle moving entries
    #    elsif ( $k eq "move" ) {
    #        my $new_target_type = $json->{target_type};
    #        my $new_target_id   = $json->{target_id};
    #        $self->target_type($new_target_type);
    #        $self->target_id($new_target_id);
    #        push@$changes, "moved entry to $new_target_type $new_target_id";
    #    }
        else {
            $log->debug("update $k to $v");
            my $orig = $self->$k;
            $self->$k($v);
            push @$changes, "Changed $k from $orig to $v";
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

build the mongo command to do the requested update

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
    my $data    = {};

    # $log->debug("building modification from ". Dumper($json));

    my $taskset = grep { /is_task/ } keys %$json;
    while ( my ($k, $v) = each %$json ) {

        if ( $k eq "cmd" ) {
            if ( $v eq "updatetask" ) {
                $data->{'$set'}->{task} = {
                    when    => $now,
                    who     => $json->{assignee} // $user,
                    status  => $json->{taskstatus} // "open",
                };
                push @$changes, "updated task data";
            }
            if ( $v eq "maketask" ) {
                $data->{'$set'}->{is_task} = 1;
                $data->{'$set'}->{task} = {
                    when    => $now,
                    who     => $json->{assignee} // $user,
                    status  => $json->{taskstatus} // "open",
                };
                push @$changes, "made entry a task";
            }
            if ( $v eq "move" ) {
                # put stuff here to handle moves of entries
                # and don't forget to do a next in the else stanza below
                # for the data fields

            }
        }
        else {
            next if ( $k eq "assignee" or $k eq "taskstatus");
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                $data->{'$set'}->{$k} = $v;
                # this should update the html field as well (bug #35)
                if ( $k eq "body" ) {
                    $log->debug("updating body!!!!");
                    if ( $self->sanitize ) {
                        $log->debug("sanitize is set, encoding html entities");
                        $v = encode_entities($v);
                    }
                    my $orig_body_text = $self->body_plaintext;
                    $self->body($v);
                    $self->update_data_derrived_from_body($orig_body_text);;
                    $data->{'$set'}->{body_flaired} = $self->body_flaired();
                    $data->{'$set'}->{body_plaintext} = $self->body_plaintext();
                    push @$changes, "updated body of entry";
                }
                else {
                    push @$changes, "updated $k from $orig";
                }
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data->{'$set'}->{updated} = $now;
    $data->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => join(', ',@$changes),
    };
    my $modhref = {
        collection  => "entries",
        match_ref   => { entry_id   => $self->entry_id },
        data_ref    => $data,
    };
    $log->debug("modifications cmd is :".Dumper($modhref));
    return $modhref;
}

=item C<update_entities>

clear the entities attribute and repopulate with passed in aref

=cut

sub update_entities {
    my $self        = shift;
    my $entity_aref = shift;
    $self->clear_entities();
    $self->push_entities(@{$entity_aref});
}

=item C<update_target>
 
 when you update an entry, this will update the timestamp of the target
 object (alert, event, etc.)

=cut

sub update_target {
    my $self    = shift;
    my $mongo   = shift;
    my $type    = $self->target_type;
    my $id      = $self->target_id;
    my $idfield = $type . "_id";
    my $targetobj   = $mongo->read_one_document({
        collection  => $type . "s", # alert, events, incidents
        match_ref   => { $idfield => $id },
    });
    my $now = time();
    $targetobj->updated($now);
    $mongo->update_document($targetobj);
    return $type, $id;
}


=item C<move_children>

this function move the children of the current entry to this entry's parent
for example:

    entry1
        entry 3
        entry 4
            entry 5
    entry2

when deleting entry 4, entry 5 will become a child of entry 1.

=cut

sub move_children {
    my $self        = shift;
    my $env  = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $log->debug("Moving children of entry");

    my $target_id   = $self->target_id;
    my $target_type = $self->target_type;
    my $entry_id    = $self->entry_id;
    my $collection  = $env->map_thing_to_collection($target_type);
    my $parent_id   = $self->parent;

    my $cursor  = $mongo->read_documents({
        collection  => "entries",
        match_ref   => {
            parent_id   => $entry_id,
            target_id   => $target_id,
            target_type => $target_type,
        }
    });

    while ( my $entry = $cursor->next ) {
        $entry->parent($parent_id);
        $mongo->update_document($entry);
    }
}

sub update_children {
    my $self        = shift;
    my $env         = shift;
    my $target_type = shift;
    my $target_id   = shift;

    my $log         = $self->log;
    my $mongo       = $env->mongo;

    $log->debug("Hi! My name is ".$self->entry_id);
    $log->debug("    and my parent is ".$self->parent);

    my $myid    = $self->entry_id;
    my $cursor  = $mongo->read_documents({
        collection  => "entries",
        match_ref   => { parent => $myid }
    });
    $log->debug("    and I have ".$cursor->count ." children");
    

    while ( my $child_obj = $cursor->next ) {
        my $this_id     = $child_obj->entry_id;
        my $old_type    = $child_obj->target_type;
        my $old_id      = $child_obj->target_id;

        $log->debug("Asking child $this_id to update itself and its children");
        $log->debug("Child $this_id target was $old_type $old_id");

        $env->activemq->send("activity", {
            action  => "deletion",
            type    => "entry",
            id      => $this_id,
            target_type => $old_type,
            target_id   => $old_id,
        });

        $child_obj->target_type($target_type);
        $child_obj->target_id($target_id);
        $log->debug("Child $this_id target is now $target_type $target_id");

        $mongo->update_document($child_obj, $target_type, $target_id);

        $env->activemq->send("activity",{
            action  => "creation",
            type    => "entry",
            id      => $this_id,
            target_type => $target_type,
            target_id   => $target_id,
        });
        $child_obj->update_children($env);
    }
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

