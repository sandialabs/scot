package Scot::Util::Scot2;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Mojo::UserAgent;
use Data::Dumper;
use Try::Tiny::Retry ':all';
use Log::Log4perl;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;
use Log::Log4perl::Layout::PatternLayout;

=head1 Name

Scot::Util::Scot

=head1 Description

this module simplifies talking rest to the SCOT API

=cut

use Moose;
extends 'Scot::Util';


has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_servername',
);

sub _get_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "localhost";
    my $envname = "scot_util_scot2_servername";
    return $self->get_config_value($attr, $default, $envname);
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
    my $attr    = "serverport";
    my $default = 443;
    my $envname = "scot_util_scot2_serverport";
    return $self->get_config_value($attr, $default, $envname);
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
    my $attr    = "username";
    my $default = "scot-alerts";
    my $envname = "scot_util_scot2_username";
    return $self->get_config_value($attr, $default, $envname);
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
    my $attr    = "password";
    my $default = "changemenow";
    my $envname = "scot_util_scot2_password";
    return $self->get_config_value($attr, $default, $envname);
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
    my $attr    = "authtype";
    my $default = "RemoteUser";
    my $envname = "scot_util_scot2_authtype";
    return $self->get_config_value($attr, $default, $envname);
}

has api_version    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
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
        return sprintf("https://%s:%s@%s:%s/scot/api/%s/", 
            $self->username,
            $self->password,
            $servername, 
            $port,
            $ver);
    }
    return sprintf("https://%s:%s@%s/scot/api/%s/", 
        $self->username,
        $self->password,
        $servername, 
        $ver);
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
        $ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->header('X-Requested-With' => 'XMLHttpRequest');
        });
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

sub param_string_to_hash {
    my $self    = shift;
    my $params  = shift;
    my @pieces  = split(/\&/, $params);
    my $nparams = {};
    foreach my $p (@pieces) {
        my ( $attr, $value ) = split(/\=/,$p);
        if ( defined $nparams->{$attr} ) {
            if ( ref($nparams->{$attr}) eq "ARRAY" ) {
                push @{ $nparams->{$attr} }, $value;
            }
            else {
                my $temp = delete $nparams->{$attr};
                push @{ $nparams->{$attr} }, $temp, $value;
            }
        }
        else {
            $nparams->{$attr}   = $value;
        }
    }
    return $nparams;
}

sub transaction {
    my $self     = shift;
    my $verb     = shift;
    my $url      = shift;
    my $datatype = shift // 'normal'; # form | json
    my $data     = shift;
    my $log      = $self->log;
    my $ua       = $self->ua;

    my $response;
    my $tx;

    return retry {
        $log->debug("Attempting TX $verb $url $datatype");
        if ( $datatype eq "form" ) {
            $tx = $ua->$verb($url => form => $data);
        }
        elsif ($datatype eq "json" ) {
            $tx = $ua->$verb($url => json => $data);
        }
        else {
            $tx = $ua->$verb($url);
        }
        $log->debug("Got ".$tx->res->code." from server");
        unless ( $tx->res->code eq "200") {
            die $tx->res->code;
        }
        return $tx;
    }
    retry_if {
        return 1 unless ($_ eq "200");
    }
    on_retry {
        $self->clear_ua;
        $log->debug("Cleared UA, rebuilding ua (will trigger reauth)");
    }
    delay_exp {
        3, 1e5
    }
    catch {
        $log->error("All attempts of $verb $url failed: $_");
    };
}

sub do_request {
    my $self    = shift;
    my $reqhref = shift;    # ...
                            # {
                            #   action => get|put|delete|post
                            #   suffix => "stuff after /scot/api/v2/"
                            #   data   => { 
                            #       params => href,
                            #       json   => href,
                            #   }
                            # }
    my $log  = $self->log;
    my $ua   = $self->ua;
    my $base = $self->ua_base_url;

    $log->debug("Doing Request ",{filter=>\&Dumper, value => $reqhref});

    my $params  = $reqhref->{data}->{params};
    my $json    = $reqhref->{data}->{json};
    my $suffix  = $reqhref->{suffix};
    
    unless ( $suffix ) {
        $log->error("undefined suffix to append to $base");
        return "do_request_error: undef suffix to apply to $base";
    }

    my $action  = $reqhref->{action} // "get";

    if ( defined $params ) {
        if ( ref($params) ne "HASH" ) {
            $log->warn("Expected Params in HREF, attempting to convert...");
            if ( $params =~ /\=/ ) {
                $params = $self->param_string_to_hash($params);
            }
            else {
                $log->error("can not convert params into hash!");
                return "do_request_error: failed to convert params to hash";
            }
        }
    }

    my $tx;     # ... mojo ua tx object



    $log->debug("Attempting $action on $base$suffix");
    if ( $params ) {
        $log->debug("sending params: ",{filter=>\&Dumper, value=> $params});
        $tx = $self->transaction($action, $base.$suffix, "form", $params);

    }
    elsif ( $json ) {
        $log->debug("sending json: ",{filter=>\&Dumper, value=> $json});
        $tx = $self->transaction($action, $base.$suffix, "json", $json);
    }
    else {
        $tx = $self->transaction($action, $base.$suffix, undef, undef);
    }

    unless ( $tx and ref($tx) ) { 
        $log->error("SCOT transaction failed");
        say "\n\n\n\n FAILURE WILL ROBINSON! \n\n\n\n";

        $self->clear_ua;
        return $self->do_request($reqhref);
        # return "transaction error";
    }

    if ( my $response = $tx->success ) {
        $log->debug("successful $action");
        return $response->json;
    }

    my $err = $tx->error;
    $log->error("SCOT server send ". $err->{code}. " ". $err->{message});
    # $log->error("UA : ",{filter=>\&Dumper, value=> $ua});
    return "transaction_error: Server error ".$err->{code}." ".$err->{message};
}

sub get {
    my $self    = shift;
    my $request = shift;
    my $log     = $self->log;

    $log->debug("GET request with ",{filter=>\&Dumper, value=>$request});

#    request {
#        id  => optional int,
#        type => required data type you are retrieving
#        params => {
#           column_name_to_filter_on => match_value
#           sort => href of columns to sort on 
#           limit => optional int, default 50
#           offset => option int , default 0
#       }
#    }

    my $id = $request->{id};

    if ( $id ) {
        $log->debug("classic get one query");
        my $formatted_request = {
            action  => "get",
            suffix  => $request->{type} . "/" . $id,
        };
        my  $return = $self->do_request($formatted_request); 
        return $return;
    }

    my $params  = $request->{params};
    unless ( $params ) {
        $log->debug("classic get many query");
        my $formatted_request = {
            action  => "get",
            suffix  => $request->{type},
        };

        my  $return = $self->do_request($formatted_request); 
        return $return;
    }
        
    if ( ref($params) ne "HASH" ) {
        $params = $self->param_string_to_hash($params);
    }

    $log->debug("get many query with params");
    my $formatted_request = {
        action  => "get",
        suffix  => $request->{type},
        data    => {
            params  => $params
        }
    };
    my $return = $self->do_request($formatted_request); 
    return $return;
}

sub put {
    my $self    = shift;
    my $request = shift;
    my $log     = $self->log;

    $log->debug("scot PUT with ",{filter=>\&Dumper, value=>$request});

    my $id      = $request->{id};
    unless ( $id ) {
        $log->error("PUT with an ID not allowed!");
        return undef;
    }

    my $data    = $request->{data};
    unless ( $data ) {
        $log->error("PUT to $id without data not allowed!");
        return undef;
    }

    my $type    = $request->{type};
    unless ( $type ) {
        $log->error("PUT needs a target!");
        return undef;
    }

    my $formatted_request = {
        action  => "put",
        suffix  => $type."/".$id,
        data    => { json => $data},
    };
    my $return = $self->do_request($formatted_request); 
    return $return;
}

sub post {
    my $self    = shift;
    my $request = shift;
    my $log     = $self->log;

    $log->debug("scot POST with ",{filter=>\&Dumper, value=>$request});

    my $type    = $request->{type};
    unless ( $type ) {
        $log->error("POST needs a type to post to!");
        return undef;
    }

    my $data    = $request->{data};
    unless ( $data ) {
        $log->error("POST needs data to post to $type");
        return undef;
    }
    my $formatted_request = {
        action  => "post",
        suffix  => $type,
        data    => { json => $data },
    };
    my $return = $self->do_request($formatted_request); 
    return $return;
}

sub delete {
    my $self    = shift;
    my $request = shift;
    my $log     = $self->log;

    $log->debug("scot DELETE with ",{filter=>\&Dumper, value=>$request});

    my $id      = $request->{id};
    unless ( $id ) {
        $log->error("DELETE with an ID not allowed!");
        return undef;
    }

    my $type    = $request->{type};
    unless ( $type ) {
        $log->error("DELETE without target collection!");
        return undef;
    }

    my $formatted_request = {
        action  => "delete",
        suffix  => $type."/".$id,
    };
    my $return = $self->do_request($formatted_request); 
    return $return;
}

sub get_alertgroup_by_msgid {
    my $self    = shift;
    my $msgid   = shift;
    my $request = {
        type    => "alertgroup",
        params  => {
            message_id  => $msgid
        },
    };
    return $self->get($request);
}


1;
