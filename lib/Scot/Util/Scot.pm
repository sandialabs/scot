package Scot::Util::Scot;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Mojo::UserAgent;
use Data::Dumper;
use Moose;
use Try::Tiny::Retry ':all';

=head1 Name

Scot::Util::Scot

=head1 Description

this module simplifies talking rest to the SCOT API

=cut

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
    default => sub { Scot::Env->instance },
);

=item B<servername>

this is the SCOT server

=cut

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_servername',
);

sub _get_servername {
    my $self    = shift;
    my $env     = $self->env;
    my $name    = $env->servername // $ENV{SCOT_SERVERNAME};
    return $name;
}

=item B<username>

the username to access scot

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_imap_username',
);

sub _get_imap_username {
    my $self    = shift;
    my $env     = $self->env;
    return $env->imap->username // $ENV{SCOT_ALERT_USER};
}

has password => ( 
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_imap_user_pass',
);

sub _get_imap_user_pass {
    my $self    = shift;
    my $env     = $self->env;
    return  $env->imap->password // $ENV{SCOT_ALERT_PASS};
}

=item B<uapid>

for detection of forks

=cut

has uapid => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => sub { $$+0 },
);

has basic_remote_login_url => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_remote_login_url',
);

sub _build_remote_login_url {
    my $self    = shift;
    # remote user uses basic auth
    my $url     = sprintf "https://%s:%s@%s/",
                    $self->username,
                    $self->password,
                    $self->servername;
    $self->env->log->debug("url is $url");
    return $url;
}

has auth_post_url => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_post_url',
);

sub _build_post_url {
    my $self    = shift;
    return sprintf "https://%s/auth",
                    $self->servername;
}

has ua  => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_build_useragent',
);

sub _build_useragent {
    my $self    = shift;
    my $env     = $self->env;
    my $type    = $env->authtype;
    my $log     = $env->log;
    my $ua;

    if ( $type eq "SSLcert" ) {

        $log->trace("Building UA for SSLCert base Authentication");
        # TODO: test something like
        # $ua = Mojo::UserAgent->new(
        #   cert => 'client.crt',
        #   key => 'client.key'
        # );
        # return $ua;
    }

    if ( $type eq "Remoteuser" ) {

        $log->trace("Building UA for Remoteuser based Authentication");
        my $user    = $self->username;

        $ua = Mojo::UserAgent->new();
        my $url = $self->basic_remote_login_url;
        my $tx  = $ua->get($url);   # this simple get will send basic auth info
                                    # and cache digest in $ua for later use
        if ( my $res = $tx->success ) {
            $log->debug("$user Authenticated to SCOT");
        }
        else {
            $log->error("$user FAILED Authentication to SCOT!");
            # should be return undef?  should we retry?
            $log->error({filter=>\&Dumper, value=>$tx});
        }

        return $ua;
    }

    if ( $type eq "Testing" ) {
        return Mojo::UserAgent->new();
    }

    # by reaching here we are doing either LDAP or Local Authentication 
    # to access SCOT REST resources.  The only diff between ldap and local
    # is on the server back end and is of little consequense to this module
    # this module just need to post user/pass to login form and get session set

    $log->trace("Building UserAgent for LDAP/Local authentication");

    $ua     = Mojo::UserAgent->new();
    my $url = $self->auth_post_url;
    my $user= $self->username;
    my $tx  = $ua->post($url    => form => {
        user    => $user,
        pass    => $self->password,
    });

    if ( my $res = $tx->success ) {
        $log->debug("$user Authenticated to SCOT");
    }
    else {
        $log->error("$user FAILED Authentication to SCOT");
    }
    return $ua;
}

has base_url    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/scot/api/v2',
);

sub check_if_forked {
    my $self    = shift;

    # not sure this is needed, I mean, http is a stateless protocol
    # once authenticated, ua shoudl have the password digest cached
    # and the session cookie, but this arrow is my quiver if I prove 
    # to be wrong (again)
    
    # this function will reset the pid and the au cache
    
    if ( $$ != $self->uapid ) {
        $self->env->log->debug("Fork detected, restablishing...");
        $self->uapid($$);
        $self->clear_ua;
    }
}

sub get {
    my $self    = shift;
    my $col     = shift;
    my $id      = shift;

    my $url = $self->base_url . "/$col/$id";

    my $tx  = $self->get_url($url);
    my $json= $tx->res->json;
    return $json;
}

sub get_url {
    my $self    = shift;
    my $path    = shift;
    my $json    = shift;
    my $log     = $self->env->log;
    my $ua      = $self->ua;
    my $url     = sprintf "https://%s%s", $self->servername, $path;

    $log->debug("GET $url ",{filter=>\&Dumper, value=>$json});
    
    my $tx  = $ua->get($url => json => $json);

    if ( my $res = $tx->success ) {
        $log->debug("GET $url SUCCESS!");
        return $tx;
    }
    $log->error("GET $url FAILED!");
    return undef;
}

sub do_request {
    my $self    = shift;
    my $verb    = shift;
    my $url     = shift;
    my $data    = shift;

    my $env     = $self->env;
    my $log     = $env->log;
    my $ua      = $self->ua;

    my $params;
    my $json;

    if ( $data->{params} ) {
        $params = $data->{params};
    }
    if ( $data->{json} ) {
        $json   = $data->{json};
    }

    if ( $params ) {
        $url .= "?".$params;
    }

    $log->trace("[SCOTUA] $verb $url");

    my $tx = retry {
        $ua->$verb($url);
    }
    on_retry {
        $log->trace("[SCOTUA] retrying $verb $url");
    }
    delay_exp {
        3, 10000
    }
    catch {
        $log->error("$verb failed!", 
                    {filter =>  \&Dumper, value => $_->error});
    };
    return $tx;
}

sub post {
    my $self    = shift;
    my $path    = shift;
    my $json    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = sprintf "https://%s%s", $self->servername, $path;
    my $ua      = $self->ua;

    $log->debug("POST $url ",{filter=>\&Dumper, value=>$json});

    my $tx  = $self->do_request("post", $url, { json => $json });
    return $tx;
}

sub put {
    my $self    = shift;
    my $path    = shift;
    my $json    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = sprintf "https://%s%s", $self->servername, $path;
    my $ua      = $self->ua;

    $log->debug("PUT $url ",{filter=>\&Dumper, value=>$json});

    my $tx  = $ua->put($url => json => $json);

    if ( my $res = $tx->success ) {
        $log->debug("PUT $url success!");
        return $tx;
    }
    
    $log->error("PUT $url Failed");
    return undef;
}


# TODO: rest of the verbs

1;

