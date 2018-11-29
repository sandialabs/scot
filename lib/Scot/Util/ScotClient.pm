package Scot::Util::ScotClient;

use strict;
use warnings;
# use v5.18;

use Mojo::UserAgent;
use Try::Tiny::Retry qw/:all/;
use MIME::Base64;
use namespace::autoclean;
use Data::Dumper;
use Moose;

extends 'Scot::Util';

=head1 Name

Scot::Util::ScotClient

=head1 Description

This Util module will allow a programe to communicate with a SCOT
server via the REST API.

=head1 Extends

Scot::Util

=head1 Attributes

=over 4

=cut

=item B<servername>

the servername of the SCOT server you wish to communicate with
Defaults to "localhost".  Configuration attribute is "servername".
Environment variable override is "scot_util_scotclient_servername"

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
    my $attr    = "servername";
    my $default = "localhost";
    my $envname = "scot_util_scotclient_servername";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<serverport>

the port of the SCOT server you wish to communicate with
Defaults to "443".  Configuration attribute is "serverport".
Environment variable override is "scot_util_scotclient_serverport"

=cut

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
    my $envname = "scot_util_scotclient_serverport";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<username>

the username on the SCOT server that you are connecting to
Defaults to "scot-alerts".  Configuration attribute is "username".
Environment variable override is "scot_util_scotclient_username"

=cut

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
    my $envname = "scot_util_scotclient_username";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<password>

the password of username  on the SCOT server that you are connecting to
Defaults to "changemenow".  Configuration attribute is "password".
Environment variable override is "scot_util_scotclient_password"

=cut

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
    my $envname = "scot_util_scotclient_password";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<auth_type>

How do you want to authenticate to SCOT.  Basic (username and password)
TODO: App token
Defaults to "basic".  Configuration attribute is "auth_type".
Environment variable override is "scot_util_scotclient_auth_type"

=cut

has auth_type   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_auth_type',
);

sub _get_auth_type {
    my $self    = shift;
    my $attr    = "auth_type";
    my $default = "basic";
    my $envname = "scot_util_scotclient_auth_type";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<base_url>

after the servname the prefix uri segment
defaults to "scot/api/v2"
environment variable to override "scot_util_scotclient_base_url"

=cut

has base_uri => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_base_uri',
);

sub _build_base_uri {
    my $self    = shift;
    my $attr    = "base_uri";
    my $default = "scot/api/v2";
    my $envname = "scot_util_scotclient_base_uri";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<auth_header>

create the header for SCOT authentication
Build from attributes auth_type, username, and password

=cut

has auth_header => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_auth_header',
);

sub _build_auth_header {
    my $self    = shift;

    my $mash;
    if ( $self->api_key eq ' ' ) {
        my $user    = $self->username;
        my $pass    = $self->password;
        $mash       = $user . ":" . $pass;
    }
    else {
        # note to monday:  need to check auth type for api key
        # and use that instead
        $mash   = $self->api_key;
        
    }
    chomp(my $encoded = encode_base64($mash));
    return sprintf("%s %s", $self->auth_type, $encoded);
    
}

has api_key => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    default     => ' ',
);

=item B<api_key_header>

create the data for authorization header when using api key

=cut

has api_key_header => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_api_key_header',
);

sub _build_api_key_header {
    my $self    = shift;
    my $user    = $self->api_key;
    my $log     = $self->log;
    $log->debug("BUILDING api_key_header from $user");
    chomp(my $encoded = encode_base64($user));
    # my $string = sprintf("%s %s", "apikey", $encoded);
    my $string = sprintf("%s %s", "apikey", $user);
    $log->debug("string is $string");
    return $string;
}

=item B<uapid>

The pid of the client,  for fork detection.

=cut

has uapid   => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => sub { $$ + 0 },
);

=item B<http_method>

http or https.  Default is https.  config attribute is "http_method"
environment variable override is "scot_util_scotclient_http_method"

=cut

has http_method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_http_method',
);

sub _build_http_method {
    my $self    = shift;
    my $attr    = "http_method";
    my $default = "https";
    my $envname = "scot_util_scotclient_http_method";
    return $self->get_config_value($attr, $default, $envname);
}

=item B<ua>

reference to the Mojo::UserAgent object that performs the communication
tasks to the SCOT server.

=cut

has ua  => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_build_ua',
);

sub _build_ua {
    my $self    = shift;
    my $ua      = Mojo::UserAgent->new;
    my $log     = $self->log;

    $log->debug("Building UA");

    if ( $self->auth_type eq "basic" ) {
        $log->debug("adding basic auth header callback");
        # add the Authorization header
        $ua->on( start => sub {
            my $ua  = shift;
            my $tx  = shift;
            $tx->req->headers->header(
                'Authorization' => $self->auth_header,
                'Host' => $self->servername,
            );
        });
    }

    if ( $self->auth_type eq "local" ) {
        $log->debug("Using form based login");
        # need to send form to login and then ua will cache encrypted 
        # session cookie
        my $url = sprintf("%s://%s:%s/auth",
                          $self->http_method,
                          $self->servername,
                          $self->serverport);
        my $tx  = $ua->post( $url => form => {
            user    => $self->username,
            pass    => $self->password,
        });
        if ( my $response = $tx->success ) {
            $log->debug("User ".$self->username." authenticated.");
        }
        else {
            $log->error("User ".$self->username." FAILED Authentication");
        }
    }

    if ( $self->auth_type =~ /apikey/i ) {
        $log->debug("adding auth header callback with apikey");
        my $ak = $self->api_key_header;
        $log->debug("api_key_header $ak");
        $ua->on( start  => sub {
            my $ua  = shift;
            my $tx  = shift;
            $tx->req->headers->header(
                'Authorization'     => $ak,
            );
        });
    }

    return $ua;
}

sub have_i_forked {
    my $self    = shift;
    my $log     = $self->log;

    if ( $$ != $self->uapid ) {
        $log->warn("Fork detected, clearing UA");
        $self->uapid($$);
        $self->clear_ua;
    }
}

sub tx {
    my $self    = shift;
    my $verb    = shift;    # get | put | post | delete | head
    my $uri     = shift;
    my $dtype   = shift // 'normal';    # normal | form | json 
    my $data    = shift;
    my $ua      = $self->ua;
    my $log     = $self->log;

    my $response;
    my $tx;
    my $url = sprintf("%s://%s/%s",
                      $self->http_method,
                      $self->servername,
                      $uri);

    $log->debug("Initiatiing: | $url |");

    my $accept  = { Accept => '*/*' };

    return retry {
        if ( $dtype eq "form" ) {
            $tx = $ua->$verb( $url => $accept => form => $data );
        }
        elsif ( $dtype eq "json" ) {
            $tx = $ua->$verb( $url => $accept => json => $data );
        }
        else {
            $tx = $ua->$verb( $url => $accept );
        }

        unless (defined $tx) {
            die "tx failed";
        }

        my $code = $tx->res->code;

        $log->debug("Return Code: $code");
        $log->debug($tx->res->message);

        return $tx;
    }
    retry_if {
        return 1  if ($_ =~ /tx failed/);
    }
    on_retry {
        $self->clear_ua;
    }
    delay_exp {
        3, 1e5
    }
    catch {
        warn "All attempts to $verb $url failed: $_";
    };
}



sub request {
    my $self    = shift;
    my $href    = shift;    # ...
                            # {
                            #   action  => get|put|delete|post
                            #   uri     => stuff after /scot/api/v2
                            #   data    => {
                            #       params  => href
                            #       json    => href
                            #   }
                            # }
    my $log     = $self->log;
    my $base    = $self->base_uri;
    my $action  = lc($href->{action}) // 'get';
    my $json    = $href->{data}->{json};
    my $params  = $href->{data}->{params};
    my $uri     = $href->{uri};

    unless (defined $uri) {
        $log->error("Request did not have a defined uri!");
        return undef;
    }

    if (defined $params ) {
        if ( ref($params) ne "HASH" ) {
            if ( $params =~ /\=/ ) {
                $params = $self->param_string_to_hash($params);
            }
            else {
                $log->error("Unable to parse param string!");
                return undef;
            }
        }
    }

    my $tx;
    $uri    = $self->base_uri . "/" . $uri;
    if ( defined $params ) {
        $tx = $self->tx( $action, $uri, "form", $params );
    }
    elsif ( defined $json ) {
        $tx = $self->tx( $action, $uri, "json", $json );
    }
    else {
        $tx = $self->tx( $action, $uri, undef, undef );
    }

    unless ( defined $tx and ref($tx) ) {
        $log->error("Request Failed!");
        $self->clearn_ua;
        return undef;
    }

    if ( my $response = $tx->success ) {
        return $response->json;
    }
    my $error = $tx->error;
    $log->error("Server Error: ". $error->{code} . " ". $error->{message});
    return undef;
}

sub get {
    my $self    = shift;
    my $uri     = shift;
    my $options = shift;
    my $log     = $self->log;

    $log->debug("GET $uri ", {filter=>\&Dumper, value=>$options});

    return $self->request({
        action  => "get",
        uri     => $uri,
        data    => $options,
    });
}

sub put {
    my $self    = shift;
    my $uri     = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("PUT ",{ filter => \&Dumper, value => $href });

    unless ( $uri =~ /\/\d+$/ ) {
        $log->error("PUT without an ID is not allowed!");
        return undef;
    }

    unless ( defined $href ) {
        $log->error("PUT to id with data not allowed!");
        return undef;
    }

    my $reqhref  = {
        action  => "put",
        uri     => $uri,
        data    => { json    => $href },
    };
    return $self->request($reqhref);
}

sub post {
    my $self    = shift;
    my $uri     = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("POST ", {filter=>\&Dumper, value=>$href});

    unless (defined $href) {
        $log->error("POST needs data to create ");
        return undef;
    }

    my $reqhref = {
        action  => 'post',
        uri     => $uri,
        data    => { json => $href },
    };
    return $self->request($reqhref);
}

sub delete {
    my $self    = shift;
    my $uri     = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->debug("DELETE ", { filter=>\&Dumper, value => $href});

    unless ( $uri =~ /\/\d+$/ ) {
        $log->error("DELETE without an ID not allowed!");
        return undef;
    }


    my $reqhref = {
        action  => "delete",
        uri     => $uri,
    };
    return $self->request($reqhref);
}

sub param_string_to_hash {
    my $self    = shift;
    my $params  = shift;
    my @pieces  = split(/\&/, $params);
    my $href    = {};

    foreach my $piece (@pieces) {
        my ($attr, $value) = split(/\=/,$piece);
        if ( defined $href->{$attr} ) {
            if ( ref( $href->{$attr} ) eq "ARRAY" ) {
                push @{ $href->{$attr} }, $value;
            }
            else {
                my $t = delete $href->{$attr};
                push @{ $href->{$attr} }, $t, $value;
            }
        }
        else {
            $href->{$attr} = $value;
        }
    }
    return $href;
}

sub get_alertgroup_by_msg_id {
    my $self    = shift;
    my $msgid   = shift;
    my $reqhref = {
        type    => "alertgroup",
        params  => {
            message_id  => $msgid,
        },
    };
    return $self->get($reqhref);
}

1;
