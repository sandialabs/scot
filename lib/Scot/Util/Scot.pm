package Scot::Util::Scot;

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

Scot::Util::Scot

=head1 Description

this module simplifies talking rest to the SCOT API

=cut

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_logger',
);

sub _build_logger {
    my $self    = shift;
    my $logfile = $ENV{'scot_ua_logfile'} // '/var/log/scot/scot.ua.log';

    my $log     = Log::Log4perl->get_logger("ScotUA");
    my $layout  = Log::Log4perl::Layout::PatternLayout->new(
        '%d %7p [%P] %15F{1}: %4L %m%n'
    );
    my $appender    = Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::File",
        name        => "scot_log",
        filename    => $logfile,
        autoflush   => 1,
    );
    $appender->layout($layout);
    $log->add_appender($appender);
    $log->level($TRACE);
    return $log;
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
    return  $ENV{'scot_ua_servername'} // 'localhost';
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
    return $ENV{'scot_ua_serverport'} // 443;
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
    return $ENV{'scot_ua_username'} // 'scot-alerts';
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
    return $ENV{'scot_ua_password'} // 'changeme';
}

has authtype   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_authtype',
);

sub _get_authtype {
    my $self    = shift;
    return $ENV{'scot_ua_authtype'} // 'RemoteUser';
}

has api_version    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'v2',
);

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
    my $servername  = $self->servername;
    my $port        = $self->serverport;
    my $ver         = $self->api_version;
    
    if ( $port != 443 ) {
        return sprintf("https://%s:%s/scot/api/%s/", $servername, $port,$ver);
    }
    return sprintf("https://%s/scot/api/%s/", $servername, $ver);
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
    my $type    = $self->authtype;
    my $ua;
    my $log     = $self->log;

    $log->debug("Building UserAgent, authtype = $type");
    $log->debug("                    username = ".$self->username);
    $log->debug("                    password = ".$self->password);

    if ( $type eq "SSLcert" ) {

        $log->trace("Building UA for SSLCert base Authentication");
        # TODO: test something like
        # $ua = Mojo::UserAgent->new(
        #   cert => 'client.crt',
        #   key => 'client.key'
        # );
        # return $ua;
    }

    if ( $type eq "RemoteUser" ) {

        $log->trace("Building UA for Remoteuser based Authentication");
        my $user    = $self->username;

        $ua = Mojo::UserAgent->new();
        my $url = sprintf "https://%s:%s@%s/scot/api/v2/whoami",
                    $self->username,
                    $self->password,
                    $self->servername;

        $log->trace("Getting $url");

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
    my $url = sprintf "https://%s/auth", $self->servername;
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

    $log->trace("SCOTUA performing $verb $url request");

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
            if ( $err->{code} eq "403" ) {
                die "SCOT returned 403 Forrbidden";
            }
        }
        else {
            $log->error("Error: ".$err->{message} );
            die $err->{message};
        }
    }
    $log->error("TX is ",{filter=>\&Dumper, value=>$tx});
    die "Request FUBAR";
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
            my $return =  retry {
                $self->do_request("get", $type, { json => $json });
            }
            delay_exp { 3, 1e5 }
            on_retry {
                $self->clear_ua;
            }
            catch {
                $log->error("GET ERROR: $_");
            };
            return $return;
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
    my $log     = $self->log;
    my $return  = retry {
        $self->do_request("put", "$type/$id", $data);
    }
    delay_exp { 3, 1e5 }
    on_retry { $self->clear_ua; }
    catch { $log->error("PUT ERROR: $_"); };
    return $return;
}

sub post {
    my $self    = shift;
    my $type    = shift;
    my $data    = {
        json    => shift
    };
    my $log     = $self->log;
    my $return  = retry {
        $self->do_request("post", "$type", $data);
    }
    delay_exp { 3, 1e5 }
    on_retry { $self->clear_ua; }
    catch { $log->error("POST ERROR: $_"); };
    return $return;

}

sub delete {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->log;

    return retry {
        $self->do_request("delete", "$type/$id");
    }
    delay_exp { 3, 1e5 }
    on_retry { $self->clear_ua; }
    catch { $log->error("DELETE ERROR: $_"); };

}

sub get_alertgroup_by_msgid {
    my $self    = shift;
    my $id      = shift;
    my $json    = { message_id => $id };
    my $log     = $self->log;

    return retry {
        $self->do_request("get", "alertgroup", {json => {match=>$json}});
    }
    delay_exp { 3, 1e5 }
    on_retry { $self->clear_ua; }
    catch { 
        $log->error("GET alertgroup by message_id FAIL: $_");
        return undef;
    };
}


1;
