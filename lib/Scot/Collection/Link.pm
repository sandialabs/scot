package Scot::Collection::Link;

use lib '../../../lib';
use Data::Dumper;
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTargeted
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

    my $link   = $self->create({
        pair    => [ $a, $b ],
        when    => $when,
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

    my @ematches = (
        { '$elemMatch'  => $a },
        { '$elemMatch'  => $b }
    );
    my $match   = { pair => {'$all' => \@ematches } };
    my $cursor  = $self->find($match);
    return $cursor;

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

1;
