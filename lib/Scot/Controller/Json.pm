package Scot::Controller::Json;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Util::Mongo;
use JSON;

use base 'Mojolicious::Controller';

=pod

=head1 NAME

Scot::Controller::Json - JSON API for SCOT

=head1 SYNOPSIS

use Scot::Controller::Json;
$route->to("/scot/:collection/:id")->via('get')->controller('json#get');

=head1 DESCRIPTION

This controller handles most of the request for data in SCOT
It is a RESTful like API

=head2 METHODS

=item C<get>

REST say
GET /scot/:collection   -> return an array of all collection members
GET /scot/:col/:id      -> return the record of collection member :id

SCOT will do it similarly except:
GET /scot/:col 
    will return an array of the collection suitable for display
    in a "grid" format. columns requested can be passed in or default set
    is returned.
GET /scot/:col/:id
    will return an JSON document that can be digested by the SCOT frontend
    for display.
=cut

sub get {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $thing   = $self->stash("thing");

    my $grid_settings   = $self->parse_grid_settings($self->req);
    my $cols_aref       = $self->parse_cols_requested($self->req);
    my $match_ref       = $self->add_permission_check(
                            $self->parse_match_ref($self->req));
    my $opts_ref        = {
        collection      => $thing,
        match_ref       => $match_ref,
        start           => $grid_settings->{start},
        limit           => $grid_settings->{limit},
        sort_ref        => $grid_settings->{sort_ref},
    };

    my $objs_cursor     = $mongo->read_objects($opts_ref);
    my @data            = ();

    while ( my $obj_ref = $objs_cursor->next ) {
        push @data, $obj_ref->as_hash($cols_aref);
    }
    if (scalar(@data) > 0) {
        $self->render( json => {
            action  => 'get',
            thing   => $thing,
            status  => 'ok',
            data    => \@data, 
        });
    }
    else {
        $self->render( json => {
            action  => 'get',
            thing   => $thing,
            status  => 'fail',
        });
    }
}

sub get_one {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $thing   = $self->stash("thing");
    my $id      = $self->stash("id");

    my $match_field = $thing . "_id";
    my $match_ref   = {};
    $match_ref->{$match_field} = $id;
    $match_ref  = $self->add_permission_check($match_ref);
    my $obj     = $mongo->read_one_object({
        collection  => $thing,
        match_ref   => $match_ref,
    });
    if (defined $obj) {
        $self->render( json => {
            action  => 'get_one',
            thing   => $thing,
            id      => $id,
            status  => 'ok',
            data    => $obj->as_hash
        });
    }
    else {
        $self->render( json => {
            action  => 'get_one',
            thing   => $thing,
            id      => $id,
            status  => 'failed',
        });
    }

}

=item C<put>

REST says you do the following:
PUT /scot/:collection   -> replace an entire collection 
PUT /scot/:col/:id      -> replace collection member :id

SCOT variation:
1.  Doubtful if we will implement a way to replace an entire collection, 
    because that is really risky and I can't see a reason to do it.

2.  really only expect changed fields to be sent, not entire object

=cut

sub put {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $thing   = $self->stash("thing");
    my $id      = $self->stash("id");

    my $obj     = $mongo->read_one_object({
        collection  => $thing . "s",
        match_ref   => { $thing . "_id"  => $id },
    });

    my $status = "ok";
    if ($obj->apply_changes($self->req)) {
        $log->debug("Changes written sucessfully");
        # if I have linked field ie tags, files...
        # update those by $obj and 
    }
    else {
        $log->error("Error attempting requested change");
        $status = "fail";
    }
    $self->render( json => {
        action  => 'put',
        thing   => $thing,
        id      => $id,
        status  => $status,
    });
}

=item C<post>

REST say:
POST /scot/:collection  -> create a new entry in collection and return id
POST /scot/:col/:id     -> treat :id as new collection and create an entry

SCOT variation:
1.  Doubtful if we will implement a way to create a new collection.  again,
    not really applicable to our needs.

=cut

sub post {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $thing   = $self->stash("thing");
    my $id;

    my $class   = "Scot::Model::$thing";
    my $object  = $class->new($self->req);
    my $status  = "ok";
    if ($mongo->write_object($object)) {
        $log->debug("Created object $thing");
    }
    else {
        $log->debug("Failed to Write posted object $thing");
        $status = "failed";
    }
    $self->render( json => {
        action  => 'post',
        thing   => $thing,
        id      => $id,
        status  => $status,
    });

    
}

=item C<delete>

REST say:
DELETE /scot/:collection    -> whack the entire collection
DELETE /scot/:col/:id       -> delete the refereced id

SCOT variation:

Deletion is bery, bery scary.  

=cut

sub delete {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->mongo;
    my $thing   = $self->stash("thing");
    my $id      = $self->stash("id");

}

sub parse_grid_settings {
    my $self    = shift;
    my $req     = shift;
}

sub parse_match_ref {
    my $self    = shift;
    my $req     = shift;
    my $log     = $self->app->log;
    my $mref    = {};

    foreach my $param ($req->params()) {
        $mref->{$param} = $req->param($param);
    }
    retrun $mref;
}

sub add_permission_check {
    my $self    = shift;
    my $mref    = shift;
    my $op      = shift; # read or modify
    my $log     = $self->app->log;

    if (grep { /$op/ } qw(read modify) ) {
        my $attrname    = $op . "groups";
        my $session     = $self->session;
        my $group_aref  = $session->groups();
        $mref->{$attrname} = {
            '$in'   => $group_aref,
        };
        return $mref;
    }
    else {
        $log->error("you may only add read or modify perm check not $op");
        return undef;
    }
}


1;
