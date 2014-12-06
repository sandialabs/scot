package Scot::Controller::Tasks;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Util::Mongo;
use JSON;

use Scot::Model::Entry;
use base 'Mojolicious::Controller';

sub get {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $thing       = "entry";
    my $collection  = "entries";

    my $grid_settings   = $self->parse_json_param("grid");
    my $cols_request    = $self->parse_cols_requested();
    my $match_ref       = $self->parse_match_ref($self->req);

    $match_ref->{is_task} = 1;

    my $opts_ref    = {
        collection  => $collection,
        match_ref   => $match_ref,
        start       => $grid_settings->{start},
        limit       => $grid_settings->{limit},
        sort_ref    => $grid_settings->{sort_ref}//{ status => -1},
    };

    $log->debug("Getting tasks with...".Dumper($opts_ref));

    my $cursor          = $mongo->read_documents($opts_ref);
    my $total_records   = $cursor->count();
    my @data    = ();

    while ( my $obj = $cursor->next ) {

        $obj->log($log);    # pass in the logger to the new object

        my $href    = $obj->grid_view_hash($cols_request);
        if ( defined $href ) {
            my $taskhref        = $href->{task};
            $href->{task_owner} = $taskhref->{who};
            $href->{task_when}  = $taskhref->{when};
            $href->{status}     = $taskhref->{status};
            delete $href->{task};
            push @data, $href;
        }
    }

    if (scalar(@data) > 0 ) {
        $self->render(
            json    => {
                title           => "Task List",
                action          => 'get',
                thing           => 'tasks',
                status          => 'ok',
                total_records   => $total_records,
                data            => \@data,
            }
        );
    }
    else {
        $self->render(
            json    => {
                title   => "Task List",
                action  => 'get',
                thing   => 'tasks',
                status  => 'fail',
                data    => 'no matching permitted records',
            }
        );
    }
}

sub parse_match_ref {
    my $self    = shift;
    my $req     = shift;
    my $type    = "entry";
    my $idfield = $type . "_id";
    my $env     = $self->env;
    my $log     = $env->log;
    my $filter  = $self->get_filter_json($req);

    my $match   = {};

    $log->debug("building match ref hash");

    while ( my ($k,$v) = each %{$filter}) {
        $log->debug("filter for $k is " . Dumper($v));
        if ($k =~ /id/) {
            $log->debug("id field detected, numberfying values");
            if (ref($v) eq "ARRAY") {
                @$v = map { $_ + 0 } @$v;
            }
            else {
                $v = $v + 0;
            }
        }
        if ($k eq "tags") {
            $log->debug("building tag filter");
            $match->{$idfield} = $self->get_tagged_with($type,$v);
        }
        elsif (ref($v) eq "ARRAY") {
            $log->debug("building array match filter");
            $match->{$k}    = {
                '$in'   => $v
            };
        }
        else {
            $log->debug("building regex match filter");
            $match->{$k} = qr/$v/i;
        }
    }
    return $match;
}

sub get_filter_json {
    my $self    = shift;
    my $req     = shift;
    my $fraw    = $req->param('filters');
    my $filters = {};
    
    if ( defined $fraw ) {
        my $json    = JSON->new;
           $json->relaxed(1);
        $filters    = $json->decode($fraw);
    }
    return $filters;
}

sub parse_match_ref_old {
    my $self    = shift;
    my $req     = shift;
    my $type    = "entry";
    my $idfield = $type . "_id";
    my $env     = $self->env;
    my $log     = $env->log;

    my $mref    = {};
    my @ignore  = qw(columns grid);
    my @avail   = $req->param;

    foreach my $param ( @avail ) {
        next if ( grep { /^$param$/ } @ignore );
        next if ( $param eq '' );

        $log->debug("Examining param $param");

        my @match_values    = $req->param($param);

        $log->debug("match values are ". join(', ',@match_values));

        if ( $param eq "tags" ) {
            $mref->{$idfield} = $self->get_tagged_with($type,\@match_values);
        }
        else {
            if ( scalar(@match_values) > 1 ) {
                if ($param eq "entry_id") {
                    # this hack makes the values numbers not strings
                    # cause mongo won't match stings to numbers and vv
                    @match_values = map { $_ + 0 } @match_values;
                }
                $mref->{$param} = { '$in' => \@match_values };
            }
            else {
                $mref->{$param} = $match_values[0];
            }
        }
    }
    return $mref;
}
1;




