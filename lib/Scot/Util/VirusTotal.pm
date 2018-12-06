package Scot::Util::VirusTotal;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
# use v5.18;

use Data::Dumper;
use Scot::Env;
use Mojo::UserAgent;
use namespace::autoclean;

use Moose;
extends 'Scot::Util';

has username    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_username',
    # default     => ' ',
);

sub _build_username {
    my $self    = shift;
    my $attr    = "username";
    my $default = " ";
    my $envname = "scot_util_virustotal_username";
    return $self->get_config_value($attr, $default, $envname);
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
    my $default = " ";
    my $envname = "scot_util_virustotal_password";
    return $self->get_config_value($attr, $default, $envname);
}

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => "_build_servername",
    # default     => 'www.virustotal.com/vtapi',
    # default     => 'vproxy',
);
sub _build_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "www.virustotal.com/vtapi";
    my $envname = "scot_util_virustotal_servername";
    return $self->get_config_value($attr, $default, $envname);
}

has ua          => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_build_useragent',
);

has api_key     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => "_build_api_key",
);
sub _build_api_key {
    my $self    = shift;
    my $attr    = "api_key";
    my $default = " ";
    my $envname = "scot_util_virustotal_api_key";
    return $self->get_config_value($attr, $default, $envname);
}




sub _build_useragent {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $ua      = Mojo::UserAgent->new();
    my $url     = sprintf "https://%s:%s@%s/auth/request-token",
                    $self->username,
                    $self->password,
                    $self->servername;
    my $tx      = $ua->get($url);

    if ( my $res    = $tx->success ) {
        $log->debug($self->username." authenticated to ".$self->servername);
        #$log->debug({filter=>\&Dumper, value => $tx});
        my $resp    = $tx->res;
        my $json    = $resp->json;
        $log->debug("JSON is: ",{filter=>\&Dumper, value => $json});
        my $apikey  = $json->{apikey};
        $self->api_key($apikey);
    }
    else {
        $log->error($self->username." failed to authenticate to ".$self->servername);
        $log->error({filter => \&Dumper, value => $tx});
    }
    return $ua;
}

sub do_request {
    my $self    = shift;
    my $verb    = shift;
    my $url     = shift;
    my $params  = shift;    # urlencodedvars=value&foo=bar  
    my $env     = $self->env;
    my $log     = $env->log;
    my $ua      = $self->ua;
    my $prefix  = "https://".$self->servername;


    $log->debug("[api_key] ".$self->api_key);
    $log->debug("[url]     ".$url);
    $log->debug("[params]  ".$params);

    $url    = $prefix . $url . "?apikey=".$self->api_key;
    $url    .= "&".$params if $params;

    $log->trace("[MojoUA] $verb $url");

    my $tx  = $ua->$verb($url);
    if ( my $res    = $tx->success ) {
        $log->debug("$verb successful");
        return $tx;
    }
    $log->error("$verb failed! ",{ filter =>\&Dumper, value => $tx->error});
    return undef;
}

sub get_comments {
    my $self    = shift;
    my $hash    = shift;
    my $before  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/comments/get";
    my $params  = "resource=$hash";

    $params .= "&before=$before" if $before;

    $log->trace("Getting Comments on $hash");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get comments!");
    }
    return undef;
}

sub post_comment {
    my $self    = shift;
    my $hash    = shift;
    my $comment = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/comments/get";
    my $params  = "resource=$hash";

    $params .= "&comment=$comment" if $comment;

    $log->trace("Posting Comments on $hash");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to post comments!");
    }
    return undef;
}

sub get_domain_report {
    my $self    = shift;
    my $domain  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/domain/report";
    my $params  = "domain=$domain";

    $log->trace("Getting Domain Report for $domain");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get domain report!");
    }
    return undef;
}

sub get_file_behaviour {
    my $self    = shift;
    my $hash    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/file/behaviour";
    my $params  = "hash=$hash";

    $log->trace("Getting File Behaviour for $hash");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get file behaviour!");
    }
    return undef;
}

sub get_file_network {
    my $self    = shift;
    my $hash    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/file/network-traffic";
    my $params  = "hash=$hash";

    $log->trace("Getting File Network Traffic for $hash");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get file network traffic!");
    }
    return undef;
}

sub get_file_report {
    my $self    = shift;
    my $hash    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/file/report";
    my $params  = "resource=$hash";

    $log->trace("Getting File Report for $hash");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get file report!");
    }
    return undef;
}

sub get_ipaddr_report {
    my $self    = shift;
    my $ip      = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/ip-address/report";
    my $params  = "ip=$ip";

    $log->trace("Getting IP Address Report for $ip");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get file report!");
    }
    return undef;
}

sub get_url_report {
    my $self    = shift;
    my $uri     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/url/report";
    my $params  = "url=$uri";

    $log->trace("Getting URL Report for $url");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get file report!");
    }
    return undef;
}

sub scan_url {
    my $self    = shift;
    my $uri     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/url/scan";
    my $params  = "url=$uri";

    $log->trace("Submitting URL for $url");

    if ( my $tx  = $self->do_request("post", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get file report!");
    }
    return undef;
}

__PACKAGE__->meta->make_immutable;
1;
