package Scot::App::Responder::Remoteflair;

use strict;
use warnings;
use lib '../../../../lib';

use Data::Dumper;
use Try::Tiny;
use Moose;
extends 'Scot::App::PFResponder';

has name    => (
    is      => 'ro',
    isa     => 'Str',,
    required=> 1,
    default => 'BrowserFlair',
);

has extractor => (
    is          => 'ro',
    isa         => 'Scot::Extractor::Processor',
    required    => 1,
    lazy        => 1,
    builder     => '_get_entity_extractor',
);

sub _get_entity_extractor {
    my $self    = shift;
    my $env     = $self->env;
    return $env->extractor;
}

sub get_remote_flair_obj {
    my $self    = shift;
    my $href    = shift;
    my $id      = $href->{data}->{id} + 0;

    $self->env->log->debug("Getting Remote Flair Object $id");

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Remoteflair');
    my $obj     = $col->find_iid($id);

    return $obj;
}

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("Processing Remote Browser Flair Message");

    $self->env->regex->load_entitytypes;

    my $rfobj    = $self->get_remote_flair_obj($href);

    $rfobj->update({
        '$set'  => { status => 'processing' }
    });

    my $command  = $rfobj->command;

    $log->debug("command = $command");

    if ( $command eq "flair" ) {

        my $result = $self->extractor->process_html($rfobj->html);
        # no need to send back versions of what is there
        delete $result->{text};
        delete $result->{flair};
        
        $log->debug("Enriching found entities");
        $self->enrich_entities($result);

        $rfobj->update({
            '$set' => {
                status  => 'ready',
                results => $result,
            }
        });
    }

    if ( $command eq "insert" ) {

        my $target  = $rfobj->target;
        my $result;

        if (defined $target->{id} ) {
            $result = $self->add_to_existing($rfobj);
        }
        else {
            $result = $self->create_new($rfobj);
        }
        my $status  = (defined $result->{error}) ? "error" : "ready";
        $rfobj->update({
            '$set'  => {
                status  => $status,
                results => $result,
            }
        });
    }
    return 1;
}

sub add_to_existing {
    my $self    = shift;
    my $rfobj   = shift;
    my $target  = $rfobj->target;
    my $html    = $rfobj->html;
    return $self->add_entry($target, $html);
}

sub create_new {
    my $self        = shift;
    my $rfobj       = shift;

    my $target      = $rfobj->target;
    my $collection  = $target->{type};
    my $html        = $rfobj->html;
    my $uri         = $rfobj->uri;
    my $log         = $self->env->log;

    my $normalized;
    my @tags        = (qw(browser_push));
    my @sources     = ($uri);

    if ( $collection eq "Event" ) {
        $normalized = {
            tag      => \@tags,
            source   => \@sources,
            subject  => $uri,
            status   => 'open',
            groups   => $self->env->default_groups,
        };
    }
    elsif ( $collection eq "Dispatch" ) {
        $normalized = {
            subject => $uri,
            source  => \@sources,
            tag     => \@tags,
            source_uri  => $uri,
        };
    }
    elsif ( $collection eq "Intel" ) {
        $normalized = {
            subject => $uri,
            sourc   => \@sources,
            tag     => \@tags,
        };
    }
    else {
        return { error => "unsupported collection type" };
    }

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst($collection));

    my $obj     = $col->create($normalized);
    $target->{id} = $obj->id;
    my $entry   = $self->add_entry($target, $html);
    if ( ! $obj ) {
        $log->error("Failed to create $collection!");
        return { error => "Failed to create new $collection" };
    }

    if ( defined $entry->{error} ) {
        $log->error("Failed to create entry for $collection ".$obj->id);
        return { error => "Created $collection ".$obj->id." but failed to create entry"};
    }

    return { status => "Created $collection ".$obj->id };
}

sub add_entry {
    my $self        = shift;
    my $target      = shift;
    my $html        = shift;
    my $log         = $self->env->log;


    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entry');
    my $normalized  = {
        target  => $target,
        body    => $html,
    };

    my $obj = $col->create($normalized);

    if ( ! $obj ) {
        my $msg = "Failed to create Entry on $target->{type} $target->{id}";
        $log->error($msg);
        return { error => $msg };
    }

    return { status => "Created entry ".$obj->id." on $target->{type} $target->{id}" };
}

sub enrich_entities {
    my $self        = shift;
    my $result      = shift;
    my $entities    = $result->{entities};
    my $log         = $self->env->log;

    foreach my $ehash (@$entities) {
        $log->debug("examining: ",{filter=>\&Dumper, value=>$ehash});
        my $entity = $self->get_entity($ehash);

        if ( defined $entity ) {
            $log->debug("found an entity!");
            $ehash->{count} = $self->get_count($entity);
            $ehash->{classes} = $entity->classes;
        }
    }
}

sub get_entity {
    my $self    = shift;
    my $ehash   = shift;
    my $col     = $self->env->mongo->collection('Entity');
    my $obj     = $col->find_one({ 
        type  => $ehash->{type}, 
        value => $ehash->{value}
    });
    return $obj;
}

sub get_count {
    my $self    = shift;
    my $entity   = shift;
    $self->env->log->debug("counting...");
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Link');
    return $col->get_display_count($entity);
}

1;
