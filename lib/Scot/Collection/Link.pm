package Scot::Collection::Link;

use lib '../../../lib';
use Data::Dumper;
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

sub create_from_api {
    my $self    = shift;
    return $self->create_link(@_);
}

# link creation or update
sub create_link {
    my $self    = shift;
    my $a       = shift; # href = { id: 123, type: "foo" }
    my $b       = shift; # href = { id: 124, type: "bar" }
    my $env     = $self->env;
    my $when    = shift // $env->now();
    my $log     = $env->log;

    $log->debug("CREATE LINK from ".Dumper($a)." to ".Dumper($b));

    if ( ref($a) ne "HASH" or ref($b) ne "HASH" ) {
        $log->error("Arg[0] and Arg[1] must be Hash Refs");
        return undef;
    }

    unless (defined($a->{id}) and defined($a->{type}) ) {
        $log->error("Arg[0] invalid hash");
        return undef;
    }

    unless (defined($b->{id}) and defined($b->{type}) ) {
        $log->error("Arg[1] invalid hash");
        return undef;
    }

    my $test = $self->get_link($a,$b);
    if ( $test ) {
        $log->debug("link exists, returning existing...");
        return $test;
    }

    my $link   = $self->create({
        pair    => [ $a, $b ],
        when    => $when,
    });

    return $link;
}

sub link_objects {
    my $self    = shift;
    my $a       = shift; # object
    my $b       = shift; # object
    my $env     = $self->env;
    my $when    = shift // $env->now;
    my $log     = $env->log;
    
    if ( ref($a) !~ /Scot::Model/ ) {
        $log->error("Arg[0] must be a Scot::Model::* object");
        return undef;
    }
    if ( ref($b) !~ /Scot::Model/ ) {
        $log->error("Arg[1] must be a Scot::Model::* object");
        return undef;
    }
    my $link    = $self->create({
        pair    => [
            { id    => $a->id, type => $a->get_collection_name },
            { id    => $b->id, type => $b->get_collection_name },
        ]
    });
    return $link;
}

sub get_links {
    my $self        = shift;
    my $type        = shift;
    my $id          = shift;
    my $linktype    = shift;
    my $log         = $self->env->log;

    my @ematches    = ({ '$elemMatch' => { id => $id + 0, type => $type } });

    if ( $linktype ) {
        push @ematches, { '$elemMatch' => { type => $linktype }};
    }

    my $match   = {
        pair    => { '$all' => \@ematches }
    };

    $log->debug("Searching for links matching:",{filter=>\&Dumper, value=>$match});

    my $cursor  = $self->find($match);
    return $cursor;
}

sub get_link { 
    my $self    = shift;
    my $a       = shift;
    my $b       = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $a->{id} += 0;
    $b->{id} += 0;

    my @ematches = (
        { '$elemMatch'  => $a },
        { '$elemMatch'  => $b }
    );
    my $match   = { pair => {'$all' => \@ematches } };
    
    # $log->debug("Looking for Links matching: ",
    #            { filter => \&Dumper, value => $match});
     
    my $cursor  = $self->find($match);

    if ( $cursor->count > 0 ) {
        return $cursor;
    }
    return undef;

}


sub remove_links {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $linktype= shift;
    my $linkid  = shift;

    my @ematches    = ({ '$elemMatch' => { id => $id, type => $type } });
    if ( $linktype ) {
        if ( $linkid ) { 
            push @ematches, {'$elemMatch' => { id => $linkid, type => $linktype }};
        } 
        else {
            push @ematches, {'$elemMatch' => { type => $linktype }};
        }
    }
    my $match  = { pair => {'$all' => \@ematches} };
    my $cursor = $self->find($match);
    while ( my $link = $cursor->next ) {
        $link->remove;
    }
    return;
}

sub get_entry_target {
    my $self    = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $id += 0; 

    my @ematches    = (
        { '$elemMatch' => { id => $id, type => "entry" } },
        { '$elemMatch' => { 
            type => {
                '$in'   => [ "event", 
                             "incident", 
                             "alert", 
                             "alertgroup", 
                             "intel" ]
            }
        }},
    );
    my $match   = { pair => { '$all'    => \@ematches } };

    $log->debug("Looking for entry target ",
                { filter => \&Dumper, value => $match});

    my $object  = $self->find_one($match);

    # $log->debug("Got :", { filter => \&Dumper, value => $object});

    if ($object) {
        my $pair    = $object->pair;
        my ( $type, $id );
        if ( $pair->[0]->{type} eq "entry" ) {
            $type    = $pair->[1]->{type};
            $id      = $pair->[1]->{id} + 0;
        }
        else {
            $type    = $pair->[0]->{type};
            $id      = $pair->[0]->{id} + 0;
        }
        return $type, $id;
    }
    return undef;
}


1;
