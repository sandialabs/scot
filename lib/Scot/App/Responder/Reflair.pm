package Scot::App::Responder::Reflair;

use Try::Tiny;
use Data::Dumper;
use Moose;
extends 'Scot::App::Responder';

has name => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default => 'Reflair',
);

sub process_message {
    my $self        = shift;
    my $pm          = shift;
    my $href        = shift;
    my $action      = $href->{action};
    my $type        = $href->{data}->{type};
    my $id          = $href->{data}->{id};
    my $log         = $self->log;

    $log->debug("[Wkr $$] Processing Message $action $type $id");

    if ( $action eq "created" ) {
        $log->debug("--- created message ---");
        if ( $type eq "entitytype" ) {
            $log->debug("--- entitytype ---");
            return $self->process_new_entitytype($id);
        }
    }
    $log->debug("That Message was not for me :-(");
}

sub process_new_entitytype {
    my $self    = shift;
    my $id      = shift;
    my $log     = $self->log;
    my $es      = $self->env->es;

    my $entitytype  = $self->get_entitytype($id);
    unless (defined $entitytype) {
        $log->error("Entitytype id was not found!");
        return "unknown entitytype";
    }
    my $query       = $self->build_es_query($entitytype);
    unless (defined $query) {
        $log->error("Query was not defined!");
        return "failed to build query";
    }
    my $json        = $es->search("scot", ['entry','alert'], $query);
    unless (defined $json) {
        $log->error("elasticsearch search failed");
        return "elasticsearch failed";
    }
    my @results     = $self->parse_results($json);

    foreach my $appearance (@results) {
        $log->debug("Sending message for ",{filter=>\&Dumper, value=>$appearance});
        $self->send_message($appearance);
    }
    return $id;
}

sub get_entitytype {
    my $self    = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $col     = $mongo->collection('Entitytype');

    $log->debug("looking for entiry id $id");

    my $obj     = $col->find_iid($id);
    return $obj;
}

sub build_es_query {
    my $self        = shift;
    my $entitytype  = shift;

    my $log     = $self->env->log;
    my $value   = $entitytype->value;
    my $match   = $entitytype->match;
    my $id      = $entitytype->id;
    my $json    = {
        query   => {
            match   => {
                _all    => $match
            }
        }
    };
    $log->debug("build es query ",{filter=>\&Dumper,value=>$json});
    return $json;
}

sub send_message {
    my $self    = shift;
    my $href    = shift;
    my $type    = $href->{type};
    my $id      = $href->{id};
    my $mq      = $self->env->mq;
    my $log     = $self->env->log;
    my $msg     = {
        action  => "updated",
        data    => {
            who     => "reflairer",
            type    => $type,
            id      => $id,
        }
    };

    $log->debug("Sending Notification: ", {filter=>\&Dumper, value=>$msg});
    $mq->send("/queue/flair", $msg);

    # TODO: SEND HREF to sharing queue
}

sub parse_results {
    my $self    = shift;
    my $json    = shift;
    my $log     = $self->env->log;
    my @hits    = @{$json->{hits}->{hits}};
    my @results = ();
    my %seen    = ();

    $log->debug("parsing results");

    foreach my $hit (@hits) {
        my $type    = $hit->{_type};
        $log->debug("found hit type $type");

        if ( defined $type ) {
            if ( $type eq "alert" or $type eq "entry" ) {
                my $id = $hit->{_source}->{id};
                $log->debug("$type id is $id");
                if ( defined $seen{$type}{$id} ) {
                    $log->debug("$type $id already seend");
                    next;
                }
                $seen{$type}{$id}++;
                $log->debug("$type $id being added to results");
                push @results, {
                    id      => $id,
                    type    => $type,
                };
            }
        }
    }
    return wantarray ? @results : \@results;
}


1;
