package Scot::Collection;

use v5.16;
use lib '../../lib';
use strict;
use warnings;

use Moose 2;
use Data::Dumper;
use Type::Params qw/compile/;
use Try::Tiny;
use Types::Standard qw/slurpy :types/;
use Meerkat::Cursor;
use Carp qw/croak/;
use Module::Runtime qw(require_module);
use Scot::Env;
use BSON;

extends 'Meerkat::Collection';

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
    default     => sub { Scot::Env->instance; },
);



=item B<create(%args)>

replacing Meerkat's create with one that will generate a integer id.

=cut

override 'create' => sub {
    state $check        = compile( Object, slurpy ArrayRef );
    my ($self, $args)   = $check->(@_);
    my $env = $self->env;
    my $log = $self->env->log;
    my $location    = $self->env->location;

    $log->trace("In overriden create ".ref($self));

    my @args    = ( ref $args->[0] eq 'HASH' ? %{$args->[0]} : @$args );
    my $iid     = $self->get_next_id;

    push @args, "id" => $iid;
    push @args, "location" => $location;


    $log->trace("creating with : ",{filter=>\&Dumper, value=>\@args});

    my $obj = $self->class->new( @args, _collection => $self );
    $self->_save($obj);

    $log->trace("made a ",{filter=>\&Dumper, value=>$obj});
    return $obj;
};

sub exact_create {
    state $check        = compile( Object, slurpy ArrayRef );
    my ($self, $args)   = $check->(@_);
    my $env = $self->env;
    my $log = $self->env->log;

#    $log->trace("In exact create");

    my @args    = ( ref $args->[0] eq 'HASH' ? %{$args->[0]} : @$args );

    my $obj;
    eval {
        $obj = $self->class->new( @args, _collection => $self );
        $self->_save($obj);
    };
    if ( $@ ) {
        $log->warn("\@ARGS are ", {filter=>\&Dumper, value =>\@args});
        $log->error("ERROR: $@");
    }

    return $obj;
}

override '_build_collection_name'    => sub {
    my ($self)  = @_;
    my $name    = lcfirst((split(/::/, $self->class))[-1]);
    # $self->env->log->debug("collection name will be: $name");
    return $name;
};

=item B<find_iid($id)>

meerkat's find_id works on mongo oid's
this function will use integer id's

=cut

sub find_iid {
    state $check    = compile(Object, Int);
    my ($self, $id) = $check->(@_);
    $id += 0;
    my $data    = $self->_try_mongo_op(
        find_iid => sub { $self->_mongo_collection->find_one({ id => $id }) }
    );
    return unless $data;
    return $self->thaw_object($data);
}

sub set_next_id {
    my $self    = shift;
    my $id      = shift;
    my $collection  = $self->collection_name;
    my @command        = (
        findAndModify   => "nextid",
        query           => { for_collection => $collection },
        update          => { '$set' => { last_id => $id } },
        'new'           => 1,
        upsert          => 1,
    );
    my $mongo   = $self->meerkat;
    my $iid = $self->_try_mongo_op(
        get_next_id => sub {
            my $db_name = $mongo->database_name;
            my $db      = $mongo->_mongo_database($db_name);
            my $job     = $db->run_command(\@command);
            return $job->{value}->{last_id};
        }
    );
    return $iid;
}

=item B<get_next_id()>

users hate typing in oid's on the URL, so give them a friendly integer

=cut

sub get_next_id {
    my $self        = shift;
    my $collection  = $self->collection_name;
    my @command        = (
        findAndModify   => "nextid",
        query           => { for_collection => $collection },
        update          => { '$inc' => { last_id => 1 } },
        'new'           => 1,
        upsert          => 1,
    );

    my $mongo   = $self->meerkat;

    my $id = $self->_try_mongo_op(
        get_next_id => sub {
            my $db_name = $mongo->database_name;
            my $db      = $mongo->_mongo_database($db_name);
            my $job     = $db->run_command(\@command);
            return $job->{value}->{last_id};
        }
    );
    return $id;
}

### NOT USED
### but kept because doing some cool stuff might want to reuse later
sub get_subthing {
    my $self        = shift;
    my $thing       = shift;
    my $id          = shift;
    $id += 0;
    my $subthing    = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $self->meerkat;

    ## MOSTLY replaced with override's in the each collection module.

    my $thing_class = "Scot::Model::".ucfirst($thing);

    $log->trace("Getting subthing $subthing for $thing_class");

    require_module($thing_class);
    my $thing_meta  = Moose::Meta::Class->initialize($thing_class);

    if ( $thing_meta->does_role('Scot::Role::Entriable') and 
         $subthing eq "entry" ) {

        $log->trace("We are getting Entries!");

        # entries are now "special"  and map to one thing via the 
        # target = { type => $type, id => $id } attribute

        my $entry_collection = $mongo->collection('Entry');
        my $match            = {
            'target.id'     => $id + 0,
            'target.type'   => $thing,
        };
        $log->trace("searching for ",{filter=>\&Dumper, value => $match});
        my $subcursor   = $entry_collection->find($match);
        # let's not occur this expense unless we need it
        # my $entrycount  = $entry_collection->count($match);
        # $log->trace("got ".$entrycount." entries");
        return $subcursor;
    }

    if ( $thing_meta->does_role('Scot::Role::Tags') and
         $subthing eq "tag" ) {

        my $col     = $mongo->collection('Appearance');
        my $match   = {
            type            => $subthing,
            'target.id'     => $id + 0,
            'target.type'   => $thing,
        };
        my $subcursor   = $col->find($match);
        return $subcursor;
    }
    if ( $thing_meta->does_role('Scot::Role::Sources') and
         $subthing eq "source" ) {

        my $col     = $mongo->collection('Appearance');
        my $match   = {
            type            => $subthing,
            'target.id'     => $id + 0,
            'target.type'   => $thing,
        };
        my $subcursor   = $col->find($match);
        return $subcursor;
    }

    if ( $thing_meta->does_role('Scot::Role::Entitiable') and
         $subthing eq "entity" ) {

        $log->trace("Getting Entities matching $thing:$id!");

        my $col         = $mongo->collection('Link');
        my $subcursor   = $col->get_linked_objects_cursor(
            { id    => $id + 0, type => $thing}, "entity" );
        return $subcursor;
    }

    if ( $thing eq "entity" and grep {/$subthing/} (qw(alert event intel)) ) {

        $log->trace("Getting $subthing related to entity $id");

        my $col     = $mongo->collection('Link');
        my $subcursor   = $col->get_linked_objects_cursor(
            { id => $id + 0, type => 'entity' }, $subthing);
        return $subcursor;
    }

    if ( $thing eq "alert" and $subthing eq "event" ) {
        my $ecol    = $mongo->collection('Event');
        my $subcursor   = $ecol->find({
            promoted_from => $id
        });
        return $subcursor;
    }

    if ( $thing eq "event" and $subthing eq "alert" ) {
        my $ecol    = $mongo->collection('Event');
        my $acol    = $mongo->collection('Alert');

        my $event   = $ecol->find_iid($id);
        my $pfids   = $event->promoted_from;

        my $subcursor   = $acol->find({
            id  => { '$in'  => $pfids }
        });
        return $subcursor;
    }

    if ( $thing eq "event" and $subthing eq "incident" ) {
        my $icol    = $mongo->collection('Incident');
        my $subcursor   = $icol->find({
            promoted_from   => $id
        });
        return $subcursor;
    }

    if ( $thing eq "incident" and $subthing eq "event" ) {
        my $icol    = $mongo->collection('Incident');
        my $ecol    = $mongo->collection('Event');

        my $incident   = $icol->find_iid($id);
        my $pfids   = $incident->promoted_from;

        my $subcursor   = $ecol->find({
            id  => { '$in'  => $pfids }
        });
        return $subcursor;
    }

    if ( $thing eq "alertgroup" and $subthing eq "entity" ) {
        my $acol    = $mongo->collection('Alert');
        my $cursor  = $acol->find({alertgroup => $id});
        my @aids    = map { $_->{id} } $cursor->all;
        my $col     = $mongo->collection('Link');
        my $match   = {
            'target.id'     => { '$in' => \@aids },
            'target.type'   => 'alert',
        };
        my $subcursor   = $col->find($match);
        return $subcursor;
    }

    # probably and alert/alertgroup thing 
    # and we need to look for an attribute in the kids that is named
    # after the parent that contains the id to link

    my $subcol      = $mongo->collection(ucfirst($subthing));
    my $subcursor   = $subcol->find({ $thing => $id + 0 });
    return $subcursor;
}


sub get_targets {
    my $self    = shift;
    my %params  = @_;
    my $id      = $params{target_id};
    my $thing   = $params{target_type};
    my $search  = {
        'target.type' => $thing,
        'target.id'   => $id,
    };
    $self->env->log->debug("get targets: ",{ filter =>\&Dumper, value => $search});
    my $cursor  = $self->find($search);
    return $cursor;
}

sub get_value_from_request {
    my $self    = shift;
    my $req     = shift;
    my $key     = shift;

    return  $req->{request}->{params}->{$key} //
            $req->{request}->{json}  ->{$key};
} 

# default sub, designed to be overridden in Collection/*.pm modules
# if that collection has a column like "tags" or "entry_count" that
# needs to be computed at fetch time
sub has_computed_attributes {
    my $self    = shift;
    return undef;
}

sub get_aggregate_count {
    my $self    = shift;
    my $aref    = shift;
    my $log     = $self->env->log;
    my $rawcol  = $self->_mongo_collection;
    my $result  = $rawcol->aggregate($aref);

    $log->debug("result is ".ref($result));
    $log->debug("result is ".Dumper($result));
    my @r       = $result->all;
    $log->debug("all of result: ".Dumper(\@r));


    return wantarray ? @r : \@r;
}

sub raw_get_one {
    my $self    = shift;
    my $match   = shift;
    my $rawcol  = $self->_mongo_collection;
    my $result  = $rawcol->find_one($match);
    return $result;
}

sub get_aggregate_cursor {
    my $self    = shift;
    my $cmd     = shift;
    my $col     = $self->_mongo_collection;
    my $cur     = $col->aggregate($cmd);
    return $cur;
}

sub get_default_permissions {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $env     = $self->env;

    unless (defined $type and defined $id) {
        return $env->default_groups;
    }

    my $mongo   = $self->meerkat;
    my $col     = $mongo->collection(ucfirst($type));
    my $obj     = $col->find_one({id => $id});

    unless ( $obj ) {
        return $env->default_groups;
    }

    if ( $obj->meta->does_role('Scot::Role::Permission') ) {
        return $obj->groups;
    }
    
    return $env->default_groups;
}

sub build_match_ref {
    my $self    = shift;
    my $request = shift;
    my $params  = $request->{params};
    return $self->env->mongoquerymaker->build_match_ref($params);
}

sub limit_fields {
    my $self    = shift;
    my $href    = shift;
    my $req     = shift;
    my $log     = $self->env->log;
    my $params  = $req->{request}->{params};
    my $aref    = $params->{columns};
    my %fields  = ();

    if ( defined $aref ) {
        if ( ref($aref) ne "ARRAY" ) {
            $aref = [ $aref ];  # make an array ref if we have a string
        }
    }
    $log->trace("Attrs to limit: ",{filter=>\&Dumper, value=>$aref});

    foreach my $f (@$aref) {
        $fields{$f} = 1;
    }

    if ( scalar(keys %fields) == 0 ) {
        return undef;
    }
    $log->trace("Limiting attributes to: ",{filter=>\&Dumper, value=>\%fields});
    return \%fields;
}

sub filter_fields {
    my $self    = shift;
    my $req     = shift;
    my $href    = shift;
    my $cut     = $self->limit_fields($req);
    # side effect: deletes keys out of hash 
    if ( defined $cut ) {
        foreach my $key (keys %$href) {
            if ( ! defined $cut->{$key} ) {
                delete $href->{$key};
            }
        }
    }
    else {
        $self->env->log->trace("leaving fields intact");
    }
}

sub build_limit {
    my $self    = shift;
    my $href    = shift;
    my $req     = $href->{request};
    my $params  = $req->{params};
    my $json    = $req->{json};
    
    my $limit   = $params->{limit} // $json->{limit};

    if ( defined $limit ) {
        return $limit;
    }
    return undef;
}

sub api_list {
    my $self    = shift;
    my $href    = shift;
    my $user    = shift;
    my $groups  = shift;

    my $match   = $self->build_match_ref($href->{request});

    if (  ref($self) ne "Scot::Collection::Group" 
       && ref($self) ne "Scot::Collection::Entitytype" 
       && ref($self) ne "Scot::Collection::Entity" 
       && ref($self) ne "Scot::Collection::Deleted" 
       && ref($self) ne "Scot::Collection::Link" ) {
        $match->{'groups.read'} = { '$in' => $groups };
    }

    if ( ref($self) eq "Scot::Collection::Deleted" ) {
        $match->{'data.groups.read'} = {'$in' => $groups };
    }

    if ( $href->{task_search} ) {
        # $match->{'task.status'}     = {'$exists'    => 1};
        # $match->{'metadata.status'} = {'$exists'    => 1};
        $match->{class} = "task";
    }

    $self->env->log->debug("match is ",{filter=>\&Dumper, value=>$match});

    my $cursor;
    if ( ref($self) eq "Scot::Collection::Alertgroup" ) {
        $cursor = $self->find($match);
    }
    else {
        $cursor  = $self->find($match);
    }
    # deprecated
    # my $total   = $cursor->count;
    # I hate this change.  means we are doing query twice
    my $total   = $self->count($match);

    my $limit   = $self->build_limit($href);
    if ( defined $limit ) {
        $cursor->limit($limit);
    }
    else {
        # TODO: accept a default out of env/config?
        $cursor->limit(50);
    }

    if ( my $sort   = $self->build_sort($href) ) {
        $cursor->sort($sort);
    }
    else {
        $cursor->sort({id   => -1});
    }

    if ( my $offset  = $self->build_offset($href) ) {
        $cursor->skip($offset);
    }

    return ($cursor,$total);
}

sub build_sort {
    my $self    = shift;
    my $href    = shift;
    my $params  = $href->{request}->{params} // $href->{request}->{json};
    my $sort    = $params->{sort};
    my %s       = ();

    if ( defined $sort ) {
        if ( ref($sort) ne "ARRAY" ) {
            if ( ref($sort) eq "HASH" ) {
                return $sort;
            }
            $sort = [ $sort ];
        }
        foreach my $term ( @$sort ) {
            if ( $term =~ /^\-(\S+)$/ ) {
                $s{$1}  = -1;
            }
            elsif ( $term =~ /^\+(\S+)$/ ) {
                $s{$1}  = 1;
            }
            else {
                $s{$term} = 1;
            }
        }
    }
    return \%s;
}

    
sub build_offset {
    my $self    = shift;
    my $href    = shift;
    $href    = $href->{request}; # shifting up
    return $href->{params}->{offset} // $href->{json}->{offset};
}

sub get_max_id {
    my $self    = shift;
    my $cursor  = $self->find({});
    $cursor->sort({id => -1});
    my $object  = $cursor->next;
    return $object->id;
}

sub get_collection_name {
    my $self    = shift;
    my $name    = lc((split(/::/,ref($self)))[-1]);
    return $name;
}

sub api_find {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;

    if ( $href->{collection} eq "entity" ) {
        $log->debug("finding an entity");
        if ( $href->{id} eq "byname" ) {
            my $name    = $href->{request}->{params}->{name};
            $log->debug("byname $name, please");
            my $obj     = $self->find_one({ value => $name });
            return $obj;
        }
        $log->debug("by iid, thank you");
        my $id  = $href->{id} + 0;
        my $obj = $self->find_iid($id);
        return $obj;
    }
    my $id  = $href->{id};
    if ( $id eq "undefined" ) {
        $id = 0;
    }
    else {
        $id += 0;
    }
    my $obj = $self->find_iid($id);
    return $obj;

}

sub api_create {
    my $self    = shift;
    my $href    = shift;
    my $req     = $href->{request};
    my $json    = $req->{json};
    my $params  = $req->{params};
    my @objects;

    $self->env->log->debug("api_create");

    my $object  = $self->create($req);

    push @objects, $object;

    return wantarray ? @objects : \@objects;
}

sub api_restore {
    my $self    = shift;
    my $href    = shift;
    my $req     = $href->{request};
    my $json    = $req->{json};
    my $params  = $req->{params};
    my @objects;

    $self->env->log->debug("api_restore");

    my $object  = $self->exact_create($req);

    push @objects, $object;

    return wantarray ? @objects : \@objects;
}



sub api_update {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my @uprecs  = ();
    $req->{request}->{json}->{updated} = $self->env->now;
    my %update  = $self->env->mongoquerymaker->build_update_command($req);
    
    $self->env->log->debug("api_update attempting: ",{filter => \&Dumper, value => \%update});

    my $objtype = $object->get_collection_name;
    # disallow the changing of alertgroup subjects
    if ( $objtype eq "alertgroup" ) {
        if ( defined $update{subject} ) {
            delete $update{subject};
        }
    }

    foreach my $key (keys %update) {
        my $old = '';
        if ( $object->meta->has_attribute($key) ) {
            $old    = $object->$key;
        }
        push @uprecs, {
            what        => "update",
            attribute   => $key,
            old_value   => $old,
            new_value   => $update{$key},
        };
    }

    if ( ! $object->update({'$set' => \%update}) ) {
        die "Update of object failed";
    }

    return wantarray ? @uprecs : \@uprecs;
}

sub lc_array {
    my $self    = shift;
    my $aref    = shift;
    my @lcarray = map { lc($_) } @{$aref};
    return wantarray ? @lcarray : \@lcarray;
}

sub validate_permissions {
    my $self    = shift;
    my $json    = shift;
    my $target  = shift;
    my $env     = $self->env;
    my $type    = lc((split(/::/,ref($self)))[-1]);
    my @permittables = (qw(alertgroup alert checklist entry event 
                          file guide incident intel signature));

    if ( grep {/$type/} @permittables ) {

        my $defgroups;
        if (defined $target) {
            $defgroups = $self->get_default_permissions($target->{target_type}, $target->{target_id});
        }
        else {
            $defgroups = $env->default_groups;
        }

        my $read_groups = $json->{groups}->{read} // $defgroups->{read};
        my $modify_groups = $json->{groups}->{modify} // $defgroups->{modify};

        $read_groups = $self->lc_array($read_groups);
        $modify_groups = $self->lc_array($modify_groups);

        $json->{groups} = {
            read    => $read_groups,
            modify  => $modify_groups,
        };
    }
}


1;
