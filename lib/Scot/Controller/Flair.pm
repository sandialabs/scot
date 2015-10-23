package Scot::Controller::Flair;

use lib '../../../lib';

=head1 Name

Scot::Controller::Flair

=head1 Description

Perform flairing of SCOT data

1.  Listen to the SCOT queue
2.  When a new entry or alert is posted
    a.  parse thing for entities
    b.  store entities, update data, update record
3.  profit

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::Util::EntityExtractor;
use AnyEvent::STOMP::Client;
use HTML::Entities;
use strict;
use warnings;

use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    builder     => '_get_env',
);

sub _get_env {
    return Scot::Env->instance;
}

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Util::EntityExtractor',
    required    => 1,
    lazy        => 1,
    builder     => '_get_entity_extractor',
);

sub _get_entity_extractor {
    my $self    = shift;
    return Scot::Util::EntityExtractor->new({
        log => $self->env->log,
    });
};

has base_url    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default    => "http://localhost:3000/scot/api/v2",
);

sub run {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $stomp   = new AnyEvent::STOMP::Client();

    $stomp->connect();

    $stomp->on_connected(
        sub {
            my $stomp    = shift;
            $stomp->subscribe('/topic/alert');
            $stomp->subscribe('/topic/entry');
        }
    );

    $stomp->on_message(
        sub {
            my ($stomp, $header, $body) = @_;
            $log->debug("header : ", { filter => \&Dumper, value => $header});
            $log->debug("body   : ", { filter => \&Dumper, value => $body});

            # read $body to determine alert or entry number
            my $json    = decode_json $body;
            my $type    = $json->{type};
            my $id      = $json->{id};
            my $url     = $self->base_url . "/$type/$id";
            my $ua      = Mojo::UserAgent->new;

            $log->debug("Getting $url");

            # do a REST GET of that thing
            my $tx  = $ua->get($url);

            # process through Entity Extractor

            my $record  = $tx->res->json;

            $log->debug("GET Response: ", { filter => \&Dumper, value => $record });

            if ( $record->{parsed} ) {
                $log->debug("Already flaired!");
                return;
            }

            if ( $type eq "alert" ) {
                $self->process_alert($record);
                return;
            }
            $self->process_entry($record);
        }
    );

    AnyEvent->condvar->recv;
}

sub process_alert  {
    my $self        = shift;
    my $record      = shift;
    my $extractor   = $self->extractor;
    my $env         = $self->env;
    my $log         = $env->log;

    my $data    = $record->{data};
    my $flair;
    my @entities;
    my %seen;

    TUPLE:
    while ( my ( $key, $value ) = each %{$data} ) {

        my $encoded = encode_entities($value);
        $encoded = '<html>'.$encoded.'</html>';

        if ( $key =~ /^message_id$/i ) {
            $flair->{$key} = $value;
            # might have do something like: (if process_html doesn't catch it) 
            # $flair->{$key} = $extractor->do_span(undef, "message_id", $value)
            # TODO create a test for this case
            push @entities, { value => $value, type => "message_id" };
            next TUPLE;
        }

# note self on monday.  this isn't working find out why.
        my $eehref  = $extractor->process_html($encoded);

        $flair->{$key} = $eehref->{flair};

        foreach my $entity_href (@{$eehref->{entities}}) {
            my $value   = $entity_href->{value};
            my $type    = $entity_href->{type};
            unless (defined $seen{$value}) {
                push @entities, $entity_href;
                $seen{$value}++;
            }
        }
    }

    my $ua      = Mojo::UserAgent->new;
    # save via REST PUT
    my $url = $self->base_url."/alert/$record->{id}";
    my $tx  = $ua->put($url => json => {
        data_with_flair => $flair,
        entities        => \@entities,
        parsed          => 1,
    });
}

sub process_entry {
    my $self    = shift;
    my $record  = shift;
    my $extractor   = $self->extractor;
    my $env         = $self->env;
    my $log         = $env->log;
    my $ua      = Mojo::UserAgent->new;

    my $id  = $record->{id};

    $log->trace("Processing Entry $id");

    my $data    = $record->{body};

    my $eehref  = $extractor->process_html($data);

    my $url = $self->base_url."/entry/$id";

    my $json    = {
        parsed      => 1,
        body_plain  => $eehref->{text},
        body_flair  => $eehref->{flair},
        entities    => $eehref->{entities},
    };

    $log->debug("Putting: ", { filter => \&Dumper, value => $json});

    my $tx  = $ua->put($url => json => $json);
    

}
1;
