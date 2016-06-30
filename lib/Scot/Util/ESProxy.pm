package Scot::Util::ESProxy;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Mojo::UserAgent;
use Data::Dumper;
use Moose;
use Try::Tiny::Retry ':all';
use Try::Tiny;
use Log::Log4perl;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;
use Log::Log4perl::Layout::PatternLayout;

=head1 Name

Scot::Util::ESProxy

=head1 Description

this module is used to proxy "searchkit" queries to the ES cluster

=cut

has config => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
);

has proto       => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_protocol',
);

sub _get_protocol {
    my $self    = shift;
    my $proto   = $self->config->{proto};
    my $default = $ENV{'scot_es_proto'} // 'https';
    return defined($proto) ? $proto : $default;
}

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_servername',
);

sub _get_servername {
    my $self    = shift;
    my $name    = $self->config->{servername};
    my $default = $ENV{'scot_es_servername'} // 'localhost';
    return defined($name) ? $name : $default;
}

has serverport  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_get_serverport',
);

sub _get_serverport {
    my $self    = shift;
    my $port    = $self->config->{serverport};
    my $default =  $ENV{'scot_es_serverport'} // 9200;
    return defined($port) ? $port : $default;
}

has username    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_username',
);

sub _get_username {
    my $self    = shift;
    my $name    = $self->config->{username};
    my $default = $ENV{'scot_ua_username'} // 'scot-alerts';
    return defined($name) ? $name : $default;
}

has password    => ( 
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_password',
);

sub _get_password {
    my $self    = shift;
    my $pass    = $self->config->{password};
    my $default = $ENV{'scot_ua_password'} // 'changeme';
    return defined($pass) ? $pass : $default;
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
    
    if ( $port != 443 ) {
        return sprintf("%s://%s:%s/_search/", $proto, $servername, $port);
    }
    return sprintf("%s://%s/_search/", $proto, $servername);
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

    $log->debug("Building UserAgent, ");
    $log->debug("    username = ".$self->username);
    $log->debug("    password = ".$self->password);


    my $user    = $self->username;
    my $url;

    if ( $user ne ' ' ) {
        $log->trace("Building UA for Basic Authentication");
        $ua = Mojo::UserAgent->new();
        $url = sprintf "%s://%s:%s@%s/scot/api/v2/whoami",
                    $self->proto,
                    $self->username,
                    $self->password,
                    $self->servername;
    }
    else {
        $log->trace("No Authentication.");
        $ua = Mojo::UserAgent->new();
        $url = sprintf "%s://%s/_search", $self->proto, $self->servername;
    }

    $log->trace("Getting $url");

    my $tx  = $ua->get($url);   # this simple get will send basic auth info
                                # and cache digest in $ua for later use

    if ( my $res = $tx->success ) {
        $log->debug("$user Authenticated to ES");
    }
    else {
        $log->error("$user FAILED Authentication to ES!");
        # should be return undef?  should we retry?
        $log->error({filter=>\&Dumper, value=>$tx});
    }
    return $ua;

    if ( my $res = $tx->success ) {
        $log->debug("$user Authenticated to ES");
    }
    else {
        $log->error("$user FAILED Authentication to ES");
    }
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

sub do_request {
    my $self    = shift;
    my $verb    = shift; # get, put, post, delete
    my $suffix  = shift; # stuff after /scot/api/v2/
    my $data    = shift; # json or params or both being sent with request
    my $log     = $self->log;
    my $ua      = $self->ua;
    my $url     = $self->ua_base_url . $suffix;

    $log->trace("ESUA performing $verb $url request");

    my ($params, $json) = $self->extract_pj($data);

    $log->debug("Params = $params") if ($params);
    # $log->debug("Json   = ",{filter=>\&Dumper, value => $json}) if ($json);

    if ( $params ) {
        $url    = $url . "?" . $params;
    }

    my $tx;
    if ( $json ) {
        $tx     = $ua->$verb($url => json => $json);
    }
    else {
        $tx  = $ua->$verb($url);
    }

    if ( my $res = $tx->success ) {
        $log->debug("Successful $verb");
        return $res->json;
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

sub extract_pj {
    my $self    = shift;
    my $data    = shift;
    my $params;
    my $json;

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
