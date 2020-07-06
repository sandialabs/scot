use strict;
use warnings;
use lib '../../../../lib';

package Scot::App::Responder::RecFutureProxy;

### This Responder will act as a proxy to Recorded Future
###
### Users will click on a button in an entity popup
### that will create an message in a queue
### the message will contain:
### {
###    "value": "foo.bar.com",
###    "type": "domain",
###    "id": 123
###     "entry_id": 123123123,  // optional
### }
### This proxy will then request RF data and
### store it in an entry (if provided) or create a new entry
### that is attached to the entity.

use Data::Dumper;
use Scot::Env;
use Mojo::UserAgent;
use Mojo::UserAgent::Proxy;
use HTML::Make;
use namespace::autoclean;

use Moose;
extends 'Scot::App::Responder';

# all Responders need a name
has name    => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default => 'RecFutureProxy',
);

# all responders must have a process_message for the event loop
sub process_message {
    my $self    = shift;
    my $pm      = shift;    # process management object
    my $href    = shift;    # json body of AMQ message
    my $log     = $self->log; # get the logging obj
    # destructure for convenience
    my $action  = $href->{action};
    my $type    = $href->{data}->{type};
    my $id      = $href->{data}->{id};
    my $value   = $href->{data}->{value};
    my $entryid = $href->{data}->{entry_id};

    $log->debug("[Wkr $$] Processing Message $action for $value of type $type to be stored in entry $entryid");

    if ( $action eq "lookup" ) {
        return $self->process_lookup($href->{data});
    }
    $log->debug("That message was not for me.");
}

# get the servername from the config file or default below
has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => "_build_servername",
);

sub _build_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "api.recordedfuture.com/v2/";
    my $envname = "scot_util_recfuture_servername";
    return $self->get_config_value($attr, $default, $envname);
}

# get the RF api key from the config
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
    my $envname = "scot_util_recfuture_api_key";
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

sub _build_useragent {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $ua      = Mojo::UserAgent->new();

    if ( $env->proxy ne '' ) {
        $ua->proxy->detect->http($env->proxy)->https($env->proxy);
    }
    else {
        $ua->proxy->detect;
    }
     
    # TODO: look up building the UA so that it sends the API header
    # with every request
    $ua->on(start => sub {
        my ($ua, $tx) = @_;
        $tx->req->headers->header('X-RFToken' => $self->api_key);
        #$log->debug("Request: ".$tx->req->url->clone->to_abs);
        #$log->debug("Headers: ", {filter => \&Dumper, value => $tx->req->headers});
    });
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

    my $proxy   = Mojo::UserAgent::Proxy->new;
    $proxy->detect;

    $log->debug("Proxy settings: ".$proxy->https);


    $url    = $prefix . "/". $url;
    $url    .= $params if $params;

    $log->debug("[api_key] ".$self->api_key);
    $log->debug("[params]  ".$params);
    $log->debug("[url]     ".$url);

    $log->trace("[MojoUA] $verb $url");

    my $tx  = $ua->$verb($url);
    if ( my $res    = $tx->success ) {
        $log->debug("$verb successful");
        return $tx;
    }
    $log->error("$verb failed! ",{ filter =>\&Dumper, value => $tx->error});
    return undef;
}

sub process_lookup {
    my $self    = shift;
    my $href    = shift; # the lookup data from amq
    # again destructuring for convenience
    my $type    = $href->{type};
    my $id      = $href->{id};
    my $value   = $href->{value};
    my $entryid = $href->{entry_id};

    # 1.  Request data from Recorded Future.
    my $rf_data = $self->get_rf_data($value, $type);

    if ( ! defined $rf_data ) {
        $self->env->log->error("RF Data undefined!");
        $rf_data    = {};
    }

    # 2.  Store data in SCOT
    $self->store_rf_data($rf_data, $href);
}

sub get_rf_data {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("get_rf_data: $value, $type");

    my $rf_type = $self->convert_type($type);
    # RF sample code had a '.' after value, not sure if that is a bug
    # or necessary because later comment didn't have a '.' in example
    # url.  add it back if there is an error.
    my $url     = "$rf_type/$value";
    my $params  = "?fields=entity,risk";

    $self->log->debug("Attempting RF request");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $self->log->error("Failed to get file network traffic!");
    }
    return undef;

}

sub convert_type {
    my $self    = shift;
    my $type    = shift;
    my %map     = (
        ipaddr  => 'ip',
        ipv6    => 'ip',
        md5     => 'hash',
        sha1    => 'hash',
        sha256  => 'hash',
        cve     => 'vulnerability',
        domain  => 'domain',
    );
    $self->env->log->debug("scot type $type = $map{$type}");
    return $map{$type};
}

sub store_rf_data {
    my $self    = shift;
    my $rfdata  = shift;
    my $href    = shift;

    # convert the rfdata into some html format
    # will need assistance of real data to accomplish
    my $rfhtml  = $self->htmlify_rfdata($rfdata);

    # Store the data 2 ways: 1. entity->data->{rf_data}, and
    # 2. html version in entry.

    $self->store_data($rfdata,$href);

    $self->store_entry($rfhtml, $href);

}

sub htmlify_rfdata {
    my $self    = shift;
    my $rfdata  = shift;

    # guarenteed to make your eyes bleed.  Maybe some CSS will help?
    my $element = $self->json_to_html($rfdata);
    return $element->text();
}

# recurse through the JSON and create hideous (looking) HTML
sub json_to_html {
    my $self    = shift;
    my ($input) = @_;
    my $element;
    my $table_attr = {
        style => 'border:1;'
    };

    if ( ref $input eq 'ARRAY' ) {
        $element = HTML::Make->new('ol');
        foreach my $k (@$input) {
            my $li = $element->push('li');
            $li->push($self->json_to_html($k));
        }
    }
    elsif ( ref $input eq 'HASH' ) {
        $element = HTML::Make->new('table');
        foreach my $k (sort keys %$input) {
            my $tr = $element->push('tr');
            $tr->push('th', text => $k);
            my $td = $tr->push('td');
            $td->push($self->json_to_html($input->{$k}));
        }
    }
    else {
        $element = HTML::Make->new('span', text => $input);
    }
    return $element;
}

sub store_data {
    my $self    = shift;
    my $data    = shift;
    my $href    = shift;

    my $entityid    = $href->{id} + 0; # ensure number not string

    my $entity_col  = $self->env->mongo->collection('Entity');
    my $entity      = $entity_col->find_iid($entityid);
    
    if ( defined $entity ) {
        my $edata = $entity->data;
        $edata->{rf_data} = $data;
        $entity->update({
            '$set'  => {
                data    => $edata,
            }
        });
    }
    else {
        $self->log->error("Failed to find Entity $entityid! RF store data failed");
    }
}

sub store_entry {
    my $self    = shift;
    my $html    = shift;
    my $href    = shift;
    my $entryid = $href->{entry_id} + 0; # ensure number not string
    my $entry_col   = $self->env->mongo->collection('Entry');
    my $parent  = 0;

    if ( $entryid ) {
        # entry exists, post a reply
        my $entry   = $entry_col->find_iid($entryid);
        $entry->update({
            '$set'  => {
                body    => $html,
            }
        });
    }

}


__PACKAGE__->meta->make_immutable;
1;
