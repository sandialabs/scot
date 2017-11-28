package Scot::Model::HttpRequest;

use Mojo::JSON qw(decode_json encode_json);
use Try::Tiny;
use Moose;

with 'Scot::Role::Hashable';

=h2 Purpose

this module will be used to do proper validation (eventually) of 
requests from the webserver into the SCOT application.
When complete, this will replace Api.pm::get_request_params

Examine the request from the webserver and stuff the params and json
into an HREF = {
    collection  => "collection name",
    id          => $int_id,
    subthing    => $if_it_exists,
    user        => $username,
    request     => {
        params  => $href_of_params_from_web_request,
        json    => $href_of_json_submitted
    }

params for a get many looks like
{
    match: {
        '$or' : [
            {
                col1: { '$in': [ val1, val2, ... ] },
                col2: "foobar"
            },
            {
                col3: "boombaz"
            }
        ]
    },
    sort: { 
        updated => -1,
    }
    limit: 10,
    offset: 200
}

=cut



has mojo    => (
    is       => 'ro',
    isa      => 'Scot::Controller::Api',
    required => 1,
);

=item b<collection>

So we know what collection the request is operationg on.
This is comes from mojo's stash

=cut

has collection  => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy        => 1,
    builder  => '_get_collection',
);

sub _get_collection {
    my $self = shift;
    my $mojo = $self->mojo;
    
    return $mojo->stash('thing') // 'unknown';
}

has id      => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    required    => 1,
    lazy        => 1,
    builder     => '_get_id',
);

sub _get_id {
    my $self    = shift;
    my $mojo    = $self->mojo;
    return $mojo->stash('id') // undef;
};

has subthing => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    lazy        => 1,
    builder     => '_get_subthing',
);

sub _get_subthing {
    my $self    = shift;
    my $mojo    = $self->mojo;
    return $mojo->stash('subthing') // undef;
}

has subid      => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    required    => 1,
    lazy        => 1,
    builder     => '_get_id',
);

sub _get_subid {
    my $self    = shift;
    my $mojo    = $self->mojo;
    return $mojo->stash('subid') // undef;
};

has user => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    lazy        => 1,
    builder     => '_get_user',
);

sub _get_user {
    my $self    = shift;
    my $mojo    = $self->mojo;
    return $mojo->session('user') // undef;
}

has request => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_get_request',
);

sub _get_request {
    my $self    = shift;
    my $mojo    = $self->mojo;
    my $params  = $mojo->req->params->to_hash;
    my $json    = $mojo->req->json;

    if ( $params ) {
        foreach my $param_key ( keys %{$params} ) {
            my $value   = $params->{$param_key};
            $params->{$param_key} = $self->disambiguate($value);
        }
    }
    return {
        params  => $params,
        json    => $json,
    };
}

sub disambiguate {
    my $self    = shift;
    my $value   = shift;
    my $final;

    try {
        # make encoded json into perl hash
        $final  = decode_json($value);
    }
    catch {
        # no json to decode so stuff in whatever is here 
        $final = $value;
    };
    return $final;
}
1;
