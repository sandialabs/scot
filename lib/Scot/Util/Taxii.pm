package Scot::Util::Taxii;

use Mojo::UserAgent;
use Data::Dumper;
use XML::Simple;

use Moose;
extends 'Scot::Util';

has user => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_user',
);

sub _get_user {
    my $self    = shift;
    my $attr    = "user";
    my $default = "guest";
    my $envname = "scot_util_taxii_user";
    return $self->get_config_value($attr, $default, $envname);
}

has password => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_password',
);

sub _get_password {
    my $self    = shift;
    my $attr    = "password";
    my $default = "guest";
    my $envname = "scot_util_taxii_password";
    return $self->get_config_value($attr, $default, $envname);
}

has servername => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_servername',
);

sub _get_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "guest";
    my $envname = "scot_util_taxii_servername";
    return $self->get_config_value($attr, $default, $envname);
}

has headers => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_get_headers',
);

sub _get_headers {
    my $self    = shift;
    my $attr    = "headers";
    my $default = {
        'X-TAXII-Content-type'  => 'urn:taxii.mitre.org:message:xml:1.1',     
        'X-TAXII-Protocol'      => 'urn:taxii.mitre.org:protocol:http:1.0',     
        'X-TAXII-Services'      => 'urn:taxii.mitre.org:services:1.1',     
        'Content-Type'          => 'application/xml',
    };
    my $envname = "scot_util_taxii_headers";
    return $self->get_config_value($attr, $default, $envname);
}

has auth_header => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_auth_header',
);

sub _build_auth_header {
    my $self    = shift;
    my $mash    = $self->user . ":" .$self->password;
    chomp(my $encoded = encode_base64($mash));
    return sprintf("%s %s", "Basic", $encoded);
}

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

    $log->debug("Building Taxii user agent");

    my $headers = $self->headers;
    $headers->{Authorization} = $self->auth_header;

    $ua->on(start => sub {
        my $ua  = shift;
        my $tx  = shift;
        $tx->req->headers->header(%$headers);
    });
    return $ua;
}

has discovery_request_xml => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_discovery_request_xml',
);

sub _build_discovery_request_xml {
    my $self    = shift;
    my $attr    = "disovery_request_xml";
    my $default = qq{
<Discovery_Request xmlns="http://taxii.mitre.org/messages/taxii_xml_binding-1.1" message_id="1"/>
    };
    my $envname = "scot_util_taxii_disovery_request_xml";
    return $self->get_config_value($attr, $default, $envname);
}

has collection_request_xml => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_discovery_request_xml',
);

sub _build_collection_request_xml {
    my $self    = shift;
    my $attr    = "disovery_request_xml";
    my $default = qq{
<taxii_11:Collection_Information_Request xmlns:taxii_11="http://taxii.mitre.org/messages/taxii_xml_binding-1.1" message_id="2"/>
    };
    my $envname = "scot_util_taxii_collection_request_xml";
    return $self->get_config_value($attr, $default, $envname);
}

sub discover_collection_addresses {
    my $self        = shift;
    my $ua          = $self->ua;
    my $disco_url   = $self->discovery_url;
    my $tx  = $ua->post(
        $disco_url => 
        {Accept => 'application/xml' } => 
        $self->discovery_request_xml
    );
    my $href    = XMLin($tx->result->content->asset->slurp, ForceArray => 1);
    
    my @cols    = ();
    foreach my $service_instance (@{$href->{'taxii_11:Service_Instance'}}) {
        if ($service_instance->{service_type} eq "COLLECTION_MANAGEMENT" ) {
            push @cols, @{$service_instance->{'taxii_11:Address'}};
        }
    }
    return wantarray ? @cols : \@cols;
}

sub get_collections {
    my $self        = shift;
    my @addresses   = $self->discover_collection_addresses;
    my $address     = pop @addresses;
    my $tx          = $self->ua->post(
        $address            => 
        { Accept => '*/*' } =>
        $self->collection_request_xml
    );
    my $href    = XMLin($tx->result->content->asset->slurp, ForceArray => 1);
    my %coladdr = ();

    my $collections = $href->{'taxi_11:Collection'};

    foreach my $chref (@$collections) {
        $coladdr{$chref->{collection_name}} =  
            $chref->{'taxii_11:Polling_Service'}->{'taxii_11:Address'};
    }

    return wantarray ? %coladdr : \%coladdr;
}

has collection_poll_request_xml => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => q{
<taxii_11:Poll_Request 
 xmlns:taxii_11="http://taxii.mitre.org/messages/taxii_xml_binding-1.1"
 message_id="42158"
 collection_name="%s">
    <taxii_11:Poll_Parameters allow_asynch="false">
        <taxii_11:Response_Type>FULL</taxii_11:Response_Type>
    </taxii_11:Poll_Parameters>
</taxii_11:Poll_Request>
    },
);

sub get_collection_data {
    my $self    = shift;
    my $colname = shift;
    my $req     = $self->collection_poll_request_xml;
    my $coladdr = $self->get_collections;
    my $addr    = $coladdr->{$colname};
    my $tx      = $self->ua->post($addr => {Accept => '*/*'} => $req);
    my $xml     = XMLin($tx->result->content->asset->slurp, ForceArray => 1);
    return wantarray ? %$xml : $xml;
}



1;
