package Scot::Util::Mongo;

use lib '../lib';
use lib '../../../lib';
use strict;
use warnings;
use v5.10;

use MongoDB;
use MongoDB::OID;
use File::Slurp;
use File::Type;
use JSON;
use FileHandle;
use Time::HiRes qw(gettimeofday);
use Data::Dumper;
use Scot::Util::Cursor;

use Moose;
use namespace::autoclean;

=head1 Scot::Util::Mongo

This module provides methods to work with a SCOT mongodb instance.

=head2 Attributes

=over 4

=item C<config>

Hash reference to the parsed scot.json file

=cut

has config      => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

=item C<log>

reference to the Log::Log4Perl logger 

=cut

has 'log'       => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

#has client      => (
#    is          => 'ro',
#    isa         => 'MongoDB::Client',
#    required    => 1,
#    lazy        => 1,
#    builder     => '_build_mongo_client',
#);

=item C<db>

reference to the MongoDB::Database connection

=cut

has db          => (
    is          => 'ro',
    isa         => 'MongoDB::Database',
    required    => 1,
    lazy        => 1,
    builder     => '_build_db_handle',
);

=back

=cut

sub _build_db_handle {
    my $self        = shift;
    my $log         = $self->log;
    my $config      = $self->config;
    my $dbconf      = $config->{database};


    my @connection_options  = (
        host        => $dbconf->{host},
        find_master => $dbconf->{find_master},
        w           => $dbconf->{write_safety},
        query_timeout   => -1,
        timeout         => 600000,
    );

    $log->info("---- Mongo client connection build ---");
    $log->info("---- host:    ".$dbconf->{host});
    $log->info("---- port:    ".$dbconf->{port});
    $log->info("---- name:    ".$dbconf->{db_name});
    $log->info("---- user:    ".$dbconf->{user});

    my $connection  = MongoDB::MongoClient->new(@connection_options);
#    $connection->authenticate(
#        $dbconf->{db_name},
#        $dbconf->{user},
#        $dbconf->{pass},
#    );

    return $connection->get_database($dbconf->{db_name});
}

=head2 Methods

=over 4

=item C<mongo_had_error>

checks the last_error condition of the mongodb.  mostly used internally to this module.

=cut

sub mongo_had_error {
    my $self    = shift;
    my $db      = $self->db;
    my $log     = $self->log;

    my $error_href  = $db->last_error;

    if ($error_href->{'err'}) {
        $log->error("Mongo ERROR detected.  ",
                    { filter => \&Dumper, value => $error_href});
        return 1;
    }
    $log->trace("Mongo returned ", 
                { filter => \&Dumper, value => $error_href});
    return undef;
}

=item C<extract_collection_name(I<$model>)>

Give it the model name (e.g. Scot::Model::Alert) and it will return
the collections name (e.g. alerts).

=cut

sub extract_collection_name {
    my $self    = shift;
    my $model   = shift;
    my $name    = ( split(/::/, ref($model), 3) )[2];
    my $log     = $self->log;

    $log->debug("Extracted $name from ".ref($model));
    return $self->plurify_name($name);
}

=item C<plurify_name(I<$name>)>

give it a singular collection name and it will 
return a plural version.  E.g. entry yields "entries"

=cut

sub plurify_name {
    my $self    = shift;
    my $name    = shift;
    my $lastchr = substr $name, -1;
    if ($lastchr eq 'y') {
        my $junk = substr $name, -1, 1, 'ie';
    }
    my $cname   = lc($name) . "s";
    return $cname;
}

=item C<unplurify_name(I<$name>)>

give it a plural collection name and it will 
return a singular version.  E.g. entries yields "entry"

=cut

sub unplurify_name {
    my $self    = shift;
    my $name    = shift;
    (my $almost = $name) =~ s/ies/ys/;
    my $singular    = substr($almost, 0, -1);
    return $singular;
}

=item C<timestamp()>

return the integer number of seconds since the unix epoch

=cut

sub timestamp {
    my $self    = shift;
    my ($seconds, $microseconds) = gettimeofday();
    return $seconds;
}

=item C<get_int_id_field(I<$obj_ref>)>

pass in a reference to a Scot::Model object and it will return
the name of the id field.  E.g.  
    my $a = Scot::Model::Alert->new();
    say $mongo->get_int_id_field($a); # prints alert_id

=cut

sub get_int_id_field {
    my $self    = shift;
    my $object  = shift;
    my $name    = ( split(/::/, ref($object), 3) )[2];
    return lc($name) . "_id";
}

=item C<get_id_field_from_collection(I<$collection_name>)>

pass in a string of the collection name
and get the idfield name.  E.g.  entries yields entry_id

=cut

sub get_id_field_from_collection {
    my $self        = shift;
    my $collection  = shift;
    (my $almost     = $collection) =~ s/ies$/ys/;
    my $singular    = substr($almost, 0, -1);
    return $singular."_id";
}

=item C<get_next_id(I<$collection_name>)>

return the next integer id available for use to create a new object.
The last used id for a particular $collection_name is stored in the 
I<idgenerators> collection.  The act of getting the next id, increments
the last used field regardless if you use the id in your new object or
not.  Mostly, this module's insert_document routine uses this for you 
and you don't have to think about it.

=cut

sub get_next_id {
    my $self        = shift;
    my $collection  = shift;
    my $db          = $self->db;
    my $log         = $self->log;

    if ( $collection eq '' ) {
        $log->error("Failed to provide collection name to get_next_id!");
        die "Doofus, fix your code!";
    }

    $log->debug("grabbing next available id for $collection");

    # MONGO changed their run command api very stupidly
    # this used to work no problem, but now breaks 
    #my $job = $db->run_command({
    #    findAndModify   => "idgenerators",
    #    query           => { collection => $collection },
    #    update          => { '$inc' => {lastid => 1}},
    #    'new'           => 1,
    #    upsert          => 1,
    #});
    # the reason: they need a specific order to pass through
    # and instead of writing the perl driver to do this for us
    # they lazily want us to do the following:

    my %command_hash;
    my $t = tie(%command_hash, "Tie::IxHash");
    %command_hash   = (
        findAndModify   => "idgenerators",
        query           => { collection => $collection },
        update          => { '$inc' => {lastid => 1}},
        'new'           => 1,
        upsert          => 1,
    );
    my $job = $db->run_command(\%command_hash);

    if ($self->mongo_had_error) {
        $log->error("Mongo Error in get_next_id! ");
        die "Can't continue without a valid id.";
    }
    $log->trace("Got ", { filter => \&Dumper, value => $job});
    my $id = $job->{value}->{lastid};
     $log->debug("next $collection id = $id");
    return $id;
}

=item C<get_next_id_paranoid(I<$collection_name>)>

just because you are paranoid, it doesn't mean they are not out to get you!
this does the same things as get_next_id, but performs a check to see if the 
next id is already being use by some screwball abusing raw inserts into the
Scot database.  If it is in use, it will keep incrementing until it finds
one that is not in use.   While this sounds like it should be the default,
I'm not very paranoid.

=cut

sub get_next_id_paranoid {
    my $self        = shift;
    my $collection  = shift;
    my $db          = $self->db;
    my $log         = $self->log;

    $log->debug("Getting next int id for $collection (paranoid mode)");

    while ( my $id = $self->get_next_id($collection) ) {
        if ( $self->id_in_use($collection, $id) ) {
            $log->error("IID for $collection in use!");
            $log->error("...keep trying...");
        }
        else {
            return $id;
        }
    }
}

=item C<id_in_use(I<$collection, $id>)>

returns a boolean true (well, in perl that is actually just a "1") if the id 
is in use in the given collection

=cut

sub id_in_use {
    my $self        = shift;
    my $collection  = shift;
    my $id          = shift;
    my $idfield     = $self->get_id_field_from_collection($collection);
    my $match_ref   = {
        collection  => $collection,
        match_ref   => {
            $idfield    => $id
        },
    };
    my $cursor = $self->read_documents($match_ref);
    if ($cursor->count < 1) {
        return undef;
    }
    return 1;
}

=item C<document_exists(I<$object_ref>)>

Checks to see if the object exists as a document in the mongo db.
returns true if it does.

=cut

sub document_exists {
    my $self    = shift;
    my $object  = shift;
    my $idfield = $self->get_int_id_field($object);
    my $id      = $object->$idfield;
    my $log     = $self->log;

    my $cursor  = $self->read_documents({
        collection  => $self->extract_collection_name($object),
        match_ref   => { $idfield => $id },
    });

    if ($cursor->count > 0) {
        $log->debug("document ".ref($object)." id = $id already exists!");
        return 1;
    }
    return undef;
}

=item C<create_document(I<$object_ref, $paranoid>)>

Give it an object and it will create a new document in the mongodb.

B<$paranoid values>

=over 8

=item B<-1>

will accept the id stored in the object as truth and 
use it to create the document (could cause trouble!)

=item B<null>  

default behavior, get next id and run with it.

=item B<1> 

will perform a paranoid grab of the next id

=back

=cut

sub create_document {
    my $self        = shift;
    my $object      = shift;
    my $paranoid    = shift;
    my $log         = $self->log;
    my $db          = $self->db;
    my $collection  = $self->extract_collection_name($object);
    my $now         = $self->timestamp;
    my $id_field    = $self->get_int_id_field($object);
    my $next_iid;

    if (defined $paranoid) {
        if ($paranoid == 1) {
            $next_iid    = $self->get_next_id_paranoid($collection);
        }
        elsif ($paranoid == -1) {
            $next_iid   = $object->$id_field;
        }
    }
    else {
        $next_iid    = $self->get_next_id($collection);
    }

    $log->debug("Creating new document in $collection $id_field = $next_iid");

    $object->$id_field($next_iid);
    $log->debug("getting object hash");
    my $objhref = $object->as_hash;
    delete $objhref->{_id};

    $log->trace("Object Dump: ", { filter => \&Dumper, value => $objhref});

    my $colref  = $db->get_collection($collection);
    $log->trace("got collection reference");
    my $objoid  = $colref->insert($objhref);

    if ( $self->mongo_had_error ) {
        $log->error("Mongo Error Creating Document");
        return undef;
    }
    # $log->debug("Created document $next_iid in $collection");
    return $next_iid;
}

=item C<apply_update(I<$href, $opts_href>)>

Apply a "raw" update of a mongo document.  

$href   = {
    collection  => I<collection_name>, 
    match_ref   => I<match_href>,       # the match json for the mongo query
    data_ref    => I<data_href>,        # the json commands to mongo to perform the update
};

$opts_href  = {
    safe    => 1,           # default,
    upsert  => 1,           # or whatever other update options, see MongoDB documentation
};

=cut

sub apply_update {
    my $self        = shift;
    my $modhref     = shift;
    my $opts_ref    = shift // { safe => 1 };
    my $log         = $self->log;
    my $db          = $self->db;
    my $matchref    = $modhref->{match_ref};
    my $data_ref    = $modhref->{data_ref};

    $log->debug("applying a raw update of ",
                { filter => \&Dumper, value => $modhref});
    $log->debug("opts are ",
                { filter => \&Dumper, value => $opts_ref});

    my $colref      = $db->get_collection($modhref->{collection});
    my $status      = $colref->update($matchref, $data_ref, $opts_ref);

    if ( $self->mongo_had_error ) {
        $log->error("Error updating object!");
        return undef;
    }
    return 1;
}

=item C<apply_alertgroup_update(I<$href>)>

because alertgroups are "special"

=cut

sub apply_alertgroup_update {
    my $self    = shift;
    my $href    = shift;
    my $status  = 1;
    my $log     = $self->log;
    my $optshref    = $href->{opts_href} // { multiple => 1, safe => 1 };

    foreach my $set (qw(alertgroups alerts)) {
        my $modhref = $href->{$set};
        unless ($self->apply_update({
            collection  => $set,
            match_ref   => $modhref->{match_ref},
            data_ref    => $modhref->{data_ref},
        }, $optshref)) {
            $log->error("Failled to apply update to $set!");
            $status = undef;
        }
        else {
            $log->debug("I think I updated $set ");
        }
    }
    return $status;
}

=item C<raw_insert(I<$data_href, $opts_href>)>

perform a "raw" insert just like the old timers used to do back in the day.

$data_href  = { 
    collection  => collection name,
    data_ref    => href of document you are inserting,
}

$opts_href  = { } see mongodb for your option options

=cut

sub raw_insert {
    my $self    = shift;
    my $data    = shift;
    my $opts    = shift // {safe=>1};
    my $log     = $self->log;
    my $db      = $self->db;

    $log->debug("RAW INSERT!");
    my $collection_name = $data->{collection};
    my $data_ref        = $data->{data_ref};

    unless( defined $collection_name and defined $data_ref ) {
        $log->error("Failed to provide collection or data_ref");
        return undef;
    }

    my $collection  = $db->get_collection($collection_name);
    my $status      = $collection->insert($data_ref, $opts);
    if ( $self->mongo_had_error ) {
        $log->error("Error inserting raw href!");
        return undef;
    }
    return 1;
}
    
=item C<update_document(I<$object_ref>)>

Write the passed in object to the database.  Presumes that it exists.

=cut

sub update_document {
    my $self    = shift;
    my $object  = shift;
    my $log     = $self->log;
    my $db      = $self->db;
    my $colname = $self->extract_collection_name($object);
    my $now     = $self->timestamp;
    my $opts    = { safe => 1 };
    my $idfield = $object->idfield; 
    $log->debug("Update Document $colname ". $object->$idfield);

    if ($object->mongo_oid_set) {
        my $oid = $object->{_id};
        $log->trace("updating doc $oid in $colname");
        
        $object->log($log);

        my $objhref = $object->as_hash;
        delete $objhref->{_id};

        $log->trace("Writing Hashref: ",
                    { filter => \&Dumper, value => $objhref});

        my $colref  = $db->get_collection($colname);
        my $status  = $colref->update( { _id   => $oid }, $objhref, $opts);

        $log->trace("Status: ",
                    { filter => \&Dumper, value => $status});

        if ( $self->mongo_had_error ) {
            $log->error("Error updating object!");
            return undef;
        }
        $log->trace("Document saved");
        return $oid;
    }
    else {
        $log->debug("object oid not set, will use idfield");
        my $idfield = $object->idfield;
        my $id      = $object->$idfield;
        if (defined $id) {
            my $objhref = $object->as_hash;
            delete $objhref->{_id};
            my $colref  = $db->get_collection($colname);
            my $status  = $colref->update({ $idfield => $id }, $objhref, $opts);
            if ( $self->mongo_had_error ) {
                $log->error("Error updating object");
                return undef;
            }
            return $id;
        }
        else {
            $log->error("The object must have a _id or idfield set to update");
            return undef;
        }
    }
}

=item C<update_document(I<$href>)>

update a group of documents

$href   = {
    collection  => the collection holding the documents
    match_href  => the href that will match the documents ( event_id => { '$gt' => 10 } )
    data_href   => how to update them href  ( '$set' = { foo => "bar" } )
    opts_href   => mongo db opts.  [ default for this is multiple=>1, safe=>1 ]
};

=cut

sub update_documents {
    my $self    = shift;
    my $href    = shift;
    my $db      = $self->db;
    my $log     = $self->log;

    $log->trace("Updating documents: ",
                { filter => \&Dumper, value => $href});

    my $collection  = $href->{collection};
    my $matchref    = $href->{match_href};
    my $datahref    = $href->{data_href};
    my $optshref    = $href->{opts_href} // { multiple => 1, safe => 1 };

    my $colref  = $db->get_collection($collection);
    # $log->debug("got collection: $collection ". ref($colref));
    # $log->debug("colref = ", { filter => \&Dumper, value=>$colref});
    # $log->debug("matchref = ", {filter => \&Dumper, value=>$matchref});
    # $log->debug("datahref = ", {filter => \&Dumper, value=>$datahref});
    # $log->debug("optshref = ", {filter => \&Dumper, value=>$optshref});
    my $status  = $colref->update($matchref, $datahref, $optshref);

    $log->debug("Status: ",
                { filter => \&Dumper, value =>$status});

    if ( $self->mongo_had_error ) {
        $log->error("Error updating object!");
        return undef;
    }
    $log->debug("Documents updated");
    return 1;
}

=item C<read_one_document(I<$href>)>

equivalent of mongo command: db.collection.findOne({...});

$href = {
    collection  => $collection_name
    match_ref   => { match => stuff },
}

returns a Scot::Model object

=cut

sub read_one_document {
    my $self            = shift;
    my $search_href     = shift;
    my $log             = $self->log;

    $log->debug("Retrieving one document");

    $search_href->{all} = 1;
    my @docs            = $self->read_documents($search_href);
    return $docs[0];
}

=item C<read_one_raw(I<$href>)>

equivalent of mongo command: db.collection.findOne({...});

$href = {
    collection  => $collection_name
    match_ref   => { match => stuff },
}

return a href of the document

=cut

sub read_one_raw {
    my $self        = shift;
    my $search_href = shift;
    my $log         = $self->log;
    my $db          = $self->db;

    $log->debug(" RAW READ ONE ");

    my $collection  = $search_href->{collection};
    my $match_ref   = $search_href->{match_ref};
    if ($collection ne '') {
        my $colref  = $db->get_collection($collection);
        my $href    = $colref->find_one($match_ref);
        return $href;
    }
}

=item C<count_documents(I<$href>)>

sometimes you just want a number

=cut

sub count_documents {
    my $self        = shift;
    my $search_href = shift;
    my $raw         = shift;
    my $db          = $self->db;
    my $log         = $self->log;

    local $Data::Dumper::Indent = 0;
    my $host    = $self->config->{database}->{host};
    $log->debug($host." Reading documents matching ", 
                { filter => \&Dumper, value => $search_href});

    my $collection  = $search_href->{collection};
    my $match_ref   = $search_href->{match_ref};
    if ( $collection ne '' ) {
        my $colref  = $db->get_collection($collection);
        my $cursor  = $colref->find($match_ref);
        if ($self->mongo_had_error) {
            $log->error("Failed to read objects due to mongo error");
            return undef;
        }

        my $count = $cursor->count;
        return $count;
    }
    else {
        $log->error("Failed to provide collection");
        return undef;
    }
}

=item C<read_documents(I<$href>)>

The workhorse retrevial method

$href   = {
    collection  => $collection_name,
    match_ref   => $match_href,
    start       => start at this count,
    limit       => only return this many,
    sort_ref    => { column => -1 },
    all         => 1, # return array of all objects, instead of cursor
}

returns a Scot::Util::Cursor or an Array of all objects

=cut

sub read_documents {
    my $self        = shift;
    my $search_href = shift;
    my $raw         = shift;
    my $db          = $self->db;
    my $log         = $self->log;

    local $Data::Dumper::Indent = 0;
    my $host    = $self->config->{database}->{host};
    $log->debug($host." Reading documents matching ", 
                { filter => \&Dumper, value => $search_href});

    my $collection  = $search_href->{collection};
    my $match_ref   = $search_href->{match_ref};
    my $start       = $search_href->{start};
    my $limit       = $search_href->{limit};
    my $sort_ref    = $search_href->{sort_ref};
    my $all         = $search_href->{all};

    if ($collection ne '') {

        my $colref  = $db->get_collection($collection);
        my $cursor  = $colref->find($match_ref);

        my $count = $cursor->count;
        $log->debug("Retrieved $count matching documents");

        if ($self->mongo_had_error) {
            $log->error("Failed to read objects due to mongo error");
            return undef;
        }

        if ($start   ) { $cursor = $cursor->skip($start); }
        if ($limit   ) { $cursor = $cursor->limit($limit); }
        if ($sort_ref) { $cursor = $cursor->sort($sort_ref); }

        if (defined $raw ) {
            if ($all) {
                return $cursor->all;
            }
            return $cursor;
        }

        my $objcursor = Scot::Util::Cursor->new({
            'log'       => $log,
            cursor      => $cursor,
            collection  => $collection,
        });


        if ($all) {
            return  $objcursor->all;
        }
        return $objcursor;
    }
    else {
        $log->error("Failed to provide collection name in function call");
        return undef;    
    }
}

=item C<count_matching_documents(I<$href>)>

guess what this does. $href the same as read_documents

=cut

sub count_matching_documents {
    my $self    = shift;
    my $search  = shift;
    my $db      = $self->db;
    my $log     = $self->log;

    my $collection  = $search->{collection};
    my $match_ref   = $search->{match_ref};
    $log->debug("Counting documents matching: ",
                { filter => \&Dumper, value => $search});
    if ($collection ne '') {
        my $colref  = $db->get_collection($collection);
        my $cursor  = $colref->find($match_ref);

        if ($self->mongo_had_error) {
            $log->error("Failed to read objects due to mongo error");
            return undef;
        }
        my $count = $cursor->count;
        return $count;
    }
    return 0;
}

=item C<delete_document(I<$object_ref>)>

another head scratcher....

=cut

sub delete_document {
    my $self            = shift;
    my $object          = shift;
    my $db              = $self->db;
    my $log             = $self->log;
    my $collection      = $self->extract_collection_name($object);
    my $now             = $self->timestamp;
    my $id_field        = $object->idfield;
    my $del_match       = { $id_field => $object->$id_field };

    $log->debug("Deleting from $collection one document matching ",
                { filter => \&Dumper, value => $del_match});

    my $objhref         = $object->as_hash;
    my $delcollection   = $db->get_collection('deleted_'.$collection);
    delete $objhref->{_id};
    my $delobjoid       = $delcollection->insert($objhref);

    $log->debug("stuffed a backup in deleted_$collection");

    my $maincollection  = $db->get_collection($collection);
    my $objoid          = $maincollection->remove($del_match);
    if ( $self->mongo_had_error ) {
        $log->error("Mongo Error Deleting Document");
        return undef;
    }
    $log->debug("Moved document $objoid in $collection to deleted_$collection");
    return $objoid;

}

=item C<get_target_subject(I<$target, $id>)>

$target     is alert, event, incident, etc.
$id         is the id to match

and voila you get the subject of that target back

=cut


sub get_target_subject {
    my $self    = shift;
    my $target  = shift;
    my $id      = shift;
    my $log     = $self->log;

    my $collection  = $self->plurify_name($target);
    my $idfield     = $target . "_id";

    my $object  = $self->read_one_document({
        collection  => $collection,
        match_ref   => { $idfield => $id },
    });

    return $object->subject;
}

# this function does not work
sub map_reduce_get_min_max {
    my $self        = shift;
    my $collection  = shift;
    my $field       = shift;
    my $log         = $self->log;
    my $stub        = $self->get_id_field_from_collection($collection); 
    my $idfield     = $stub . "_id";
    my $db          = $self->db;

    $log->debug("Using Map/Reduce to find max value of $field in $collection");

    my $map = qq|
        function() {
            var x = { $field : this.$field, _id : this._id };
            emit(this.$idfield, { min: x, max: x } )
        }
    |;
    my $reduce = qq|
        function(key, values) {
            var res = values[0];
            for ( var i=1; i < values.length; i++ ) {
                if ( values[i].min.$field < res.min.$field ) 
                    res.min = values[i].min;
                if ( values[i].max.$field < res.max.$field )
                    res.max = values[i].max;
            }
            return res;
        }
    |;
    $log->debug("map function: $map");
    $log->debug("reduce      : $reduce");
    my $command = Tie::IxHash->new(
        "mapreduce" => $collection,
        "map"       => $map,
        "reduce"    => $reduce,
    );
    my $result  = $db->run_command($command);
    return $result;
}

sub get_latest_update {
    my $self            = shift;
    my $collection      = shift;
    my $epochfield      = shift // "updated";
    my $log             = $self->log;

    my $cursor  = $self->read_documents({
        collection  => $collection,
        match_ref   => {},
        sort_ref    => { updated => -1 },
        limit       => 1,
    });
    $cursor->immortal(1);

    if ($cursor) {
        my $href = $cursor->next_raw;
        if ($href) {
            my $epoch = $href->{$epochfield};
            $log->debug("Latest updated object in $collection is ".$epoch);
            return $epoch;
        }
        else {
            $log->error("did not get a $collection object!");
        }
    }
    else {
        $log->error("failed to get a cursor for $collection");
    }
    return undef;
}

sub aggregate { 
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $db      = $self->db;

    $log->debug("Aggregating based on ",
                { filter => \&Dumper, value => $href});

    my $collection  = $href->{collection};
    my $agg_aref    = $href->{aggregation_aref};
    my $colref      = $db->get_collection($collection);
    my $result      = $colref->aggregate($agg_aref);
    if ( $self->mongo_had_error ) {
        $log->error("Mongo Error doing Aggregation!");
        return undef;
    }
    return $result;
}

sub get_aggregate_count {
    my $self            = shift;
    my $agghref         = shift;
    my $collection      = $agghref->{collection};
    my $match_ref       = $agghref->{match_ref};
    my $agg_by_field    = $agghref->{agg_by_field};
    my $log             = $self->log;

    my $group_ref   = {
        '$group'    => {
            '_id'   => '$'.$agg_by_field,
            total   => { '$sum'  => 1 },
        },
    };
    $log->debug("group_ref is ",
                { filter => \&Dumper, value => $group_ref});

    my $result  = $self->aggregate({
        collection          => $collection,
        aggregation_aref    => [
            { '$match' => $match_ref},
            $group_ref,
        ]
    });
    $log->debug("Got aggregate result: ",
                { filter => \&Dumper, value => $result});

    return $result;
}

sub get_aggregate_sum {
    my $self            = shift;
    my $agghref         = shift;
    my $collection      = $agghref->{collection};
    my $match_ref       = $agghref->{match_ref};
    my $agg_by_field    = $agghref->{agg_by_field};
    my $sum_field       = $agghref->{sum_field};
    my $log             = $self->log;

    my $group_ref   = {
        '$group'    => {
            '_id'   => '$'.$agg_by_field,
            total   => {
                '$sum'  => '$'.$sum_field
            }
        }
    };

    $log->debug("group_ref is ",
                { fitler => \&Dumper, value =>$group_ref});

    my $result  = $self->aggregate({
        collection          => $collection,
        aggregation_aref    => [
            { '$match'  => $match_ref},
            $group_ref,
        ]
    });
    $log->debug("Got aggregate result: ",
                { filter => \&Dumper, value => $result});

    return $result;
}

sub delete_raw {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $db      = $self->db;
    my $collection  = $href->{collection};
    my $match_ref   = $href->{match_ref};

    $log->debug("deleting raw ",
                { filter => \&Dumper, value => $href});

    my $maincollection  = $db->get_collection($collection);
    my $objoid          = $maincollection->remove($match_ref);
    if ( $self->mongo_had_error ) {
        $log->error("Mongo Error Deleting Document");
        return undef;
    }
}

1;
__PACKAGE__->meta->make_immutable;
__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

