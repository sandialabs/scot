package Scot::Util::ESProxy;

use lib '../../../lib';
use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::JSON qw/encode_json decode_json/;
use Data::Dumper;
use Moose;
use Try::Tiny::Retry ':all';
use Try::Tiny;
use Log::Log4perl;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;
use Log::Log4perl::Layout::PatternLayout;
use Search::Elasticsearch;

=head1 Name

Scot::Util::ESProxy

=head1 Description

this module is used to proxy "searchkit" queries to the ES cluster

=cut

use Moose;
extends 'Scot::Util';

has proto       => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_protocol',
);

sub _build_protocol {
    my $self    = shift;
    my $attr    = "proto";
    my $default = "https";
    return $self->get_config_value($attr,$default);
}

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_servername',
);

sub _build_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "localhost";
    return $self->get_config_value($attr,$default);
}

has serverport  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_serverport',
);

sub _build_serverport {
    my $self    = shift;
    my $attr    = "serverport";
    my $default = 9200;
    return $self->get_config_value($attr,$default);
}

has username    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_username',
);

sub _build_username {
    my $self    = shift;
    my $attr    = "username";
    my $default = "scot-alerts";
    return $self->get_config_value($attr,$default);
}

has password    => ( 
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_password',
);

sub _build_password {
    my $self    = shift;
    my $attr    = "password";
    my $default = "changemenow";
    return $self->get_config_value($attr,$default);
}

has uapid   => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => sub { $$ + 0 },
);

has ua_base_url => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_base_url',
);

sub _get_base_url {
    my $self        = shift;
    my $proto       = $self->proto;
    my $servername  = $self->servername;
    my $port        = $self->serverport;
    my $log         = $self->log;

    $log->debug("$proto $servername $port");
    
    if ( $port != 443 ) {
        return sprintf("%s://%s:%s/scot/_search", $proto, $servername, $port);
    }
    return sprintf("%s://%s/scot/_search", $proto, $servername);
}

has ua  => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_get_useragent',
);

sub _get_useragent {
    my $self    = shift;
    my $ua;
    my $log     = $self->log;

    $log->trace("No Authentication.");
    IO::Socket::SSL::set_defaults(
        SSL_verify_mode => 0,
        SSL_version => "SSLv3"
    );
    $ua = Mojo::UserAgent->new();

    return $ua;
}

sub check_if_forked {
    my $self    = shift;
    my $log     = $self->log;
    if ( $$ != $self->uapid ) {
        $log->warn("Fork detected, recreating UA");
        $self->uapid($$);
        $self->clear_ua;
    }
}

sub do_request_mojo {
    my $self    = shift;
    my $verb    = lc(shift); 	    # get, put, post, delete
    my $suffix  = shift; 	        # stuff after /scot/api/v2/
    my $data    = shift;            # json or params or both being sent with request
    my $ua      = $self->ua;
    my $log     = $self->log;
    my $url     = $self->ua_base_url ;#. $suffix;

    $log->trace("ESUA performing $verb $url request");

    my ($params, $json) = $self->extract_pj($data);

    my $tx;

    if ( $json ) {
        my $href = decode_json($json);
        if ( $href->{size} == 0 ) {
            $href->{size} = undef;
        }
        my $sendjson = encode_json($href);
        $log->debug("Sending $verb to $url with ",{filter=>\&Dumper,value=>$sendjson});
        $tx     = $ua->post($url => $sendjson);
    }

    if ( my $res = $tx->success ) {
        $log->debug("Successful $verb");
        my $datahref = $res->json;
        # $log->debug("response is ",{filter=>\&Dumper, value => $res});
        $log->debug("datahref is ",{filter=>\&Dumper, value => $datahref});
        return $datahref;
    }
    else {
        my $err = $tx->error;
        if ( $err->{code} ) {
            $log->error("Error ".$err->{code}." response: ".$err->{message});
        }
        else {
            $log->error("Error: ".$err->{message} );
        }
    }
    return undef;
}

# this new do_request is for ditching searchkit.js
# we'll create our own query and return

sub do_request_new {
    my $self    = shift;
    my $eshref  = shift;            # href that corresponds to elastic search query
    my $ua      = $self->ua;
    my $log     = $self->log;
    my $url     = $self->ua_base_url ;#. $suffix;

    unless ( defined($eshref) ) {
        $log->error("FAILED to provide query HREF");
        return undef;
    }

    $eshref->{size}  = undef unless ($eshref->{size});

    my $json    = encode_json($eshref);
    $log->debug("GET to ES: $url ", { filter=>\&Dumper, value => $json });

    my $tx      = $ua->get( $url => {Accept => '*/*'} => json => $eshref);

    # $log->debug("tx json is ",{filter=>\&Dumper, value=>$tx->result->json});

    my $result  = $tx->result;

    if ( $result->is_success ) {
        $log->debug("Successful GET to ES");
        return $result->json;
    }
    else {
        my $err = $tx->error;
        if ( $err->{code} ) {
            $log->error("ERROR ".$err->{code}." response: ". $err->{message});
            if ( $err->{code} eq "403" ) {
                die "SCOT returned 403 Forbidden";
            }
        }
        else {
            $log->error("ERROR: ". $err->{message} );
            die $err->{mesage};
        }
    }
    $log->error("TX is ",{filter=>\&Dumper, value=>$tx});
    die "Request utterly failed";
}

sub extract_pj {
    my $self    = shift;
    my $data    = shift;
    my $params;
    my $json;

    $self->log->debug("data is ",{filter=>\&Dumper, value=>$data});

    if ( $data->{params} ) {
        $params = $data->{params};
    }
    if ( $data->{json} ) {
        $json = $data->{json}
    }
    return $params, $json;
}

sub get {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $json    = shift;    # {sorting, filtering}
    my $log     = $self->log;


    unless ($id) {
        $log->debug("no id so doing a get many");
        if ( $json ) {
            $log->debug("with filtering/sorting", {filter=>\&Dumper, value=>$json});
            return $self->do_request("get", $type, { json => $json });
        }
        $log->debug("straight get_many");
        return $self->do_request("get", $type);
    }
    $log->debug("getting $type $id");
    return $self->do_request("get", "$type/$id");
}

sub put {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $data    = {
        json    => shift
    };
    return $self->do_request("put", "$type/$id", $data);
}

sub post {
    my $self    = shift;
    my $type    = shift;
    my $data    = {
        json    => shift
    };
    return $self->do_request("post", "$type", $data);
}

sub delete {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;

    return $self->do_request("delete", "$type/$id");
}

sub get_alertgroup_by_msgid {
    my $self    = shift;
    my $id      = shift;
    my $json    = { message_id => $id };

    return $self->do_request("get", "alertgroup", {json => {match=>$json}});
}


1;
