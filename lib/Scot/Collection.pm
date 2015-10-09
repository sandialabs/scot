package Scot::Collection;

use v5.18;
use lib '../../lib';
use strict;
use warnings;

use Moose 2;
use Type::Params qw/compile/;
use Try::Tiny;
use Types::Standard qw/slurpy :types/;
use Meerkat::Cursor;
use Carp qw/croak/;
use Scot::Env;

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

    $log->trace("In overriden create");

    my @args    = ( ref $args->[0] eq 'HASH' ? %{$args->[0]} : @$args );
    my $iid     = $self->get_next_id;

    push @args, "id" => $iid;

    if ( $self->class->meta->does_role("Scot::Role::Permittable") ) {
        $log->trace("Checking for group permissions !!!!!!!");
        $self->get_group_permissions(\@args);
    }

    my $obj = $self->class->new( @args, _collection => $self );
    $self->_save($obj);

    return $obj;
};

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


=item B<get_next_id()>

users hate typing in oid's on the URL, so give them a friendly integer

=cut

sub get_next_id {
    my $self        = shift;
    my $collection  = $self->collection_name;
    my %command;
    my $tie         = tie(%command, "Tie::IxHash");
    %command        = (
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
            my $job     = $db->run_command(\%command);
            return $job->{value}->{last_id};
        }
    );
    return $id;
}

sub get_subthing {
    my $self        = shift;
    my $thing       = shift;
    my $id          = shift;
    my $subthing    = shift;

    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $collection;
    my $cursor;

    $log->trace("GET SUBTHING /$thing/$id/$subthing");

    try {
        $collection  = $mongo->collection(ucfirst($subthing));
    }
    catch {
        $log->error("Failed trying to get collection $subthing");
        return undef;
    };

    unless ($collection) {
        $log->error("Collection Error!");
        return undef;
    }

    my $class   = "Scot::Model::" . ucfirst($subthing);

    # things like tags and entries have a targets field and that is 
    # what we want to match

    if ( $class->meta->does_role("Scot::Role::Targets") ) {
        $log->trace("$class does Targets, retrieving...");
        $cursor = $collection->find({
            'targets.target_id'  => $id + 0,
            'targets.target_type' => $thing,
        });
        return $cursor;
    }

    # otherwise, assume the subthing has an attribute named the same as the $thing
    # and that it holds the matching ID

    $cursor = $collection->find({$thing => $id + 0});
    return $cursor;
}

sub get_group_permissions {
    my $self    = shift;
    my $aref    = shift;    # using ref allows us to modify array here 
    my $env     = $self->env;
    my $log     = $self->env->log;

    # check the araf for readgroups/modifygroups explicitly passed in from api and 
    # 
    my $rgflag = 0;
    my $mgflag = 0;
    foreach my $arg (@$aref) {
        $log->trace("arg is $arg");
        
        if ( $arg eq "readgroups" ) {
            $rgflag++;
        }
        if ( $arg eq "modifygroups" ) {
            $mgflag++;
        }
    }
    unless ($rgflag) {
        $log->trace("adding default readgroups");
        push @$aref, "readgroups" => $env->default_groups->{read};
    }
    unless ($mgflag) {
        $log->trace("adding default modifygroups");
        push @$aref, "modifygroups" => $env->default_groups->{modify};
    }

}

sub upsert_targetables {
    my $self    = shift;
    my $colname = shift;
    my $type    = shift;
    my $id      = shift;
    my @items   = @_;
    my $key     = "name";   # default field for Source

    if ( $colname eq "Tag" ) {
        $key    = "text";   
    }

    my $col = $self->meerkat->collection($colname);

    foreach my $item (@items) {
        my $object  = $col->find_one({$key => $item});
        if ($object) {
            $object->update_add( targets => {
                target_id   => $id,
                target_type => $type,
            });
        }
        else {
            $object = $col->create({
                $key    => $item,
                targets => [{
                    target_id   => $id,
                    target_type => $type,
                }],
            });
        }
    }
}
    

1;
