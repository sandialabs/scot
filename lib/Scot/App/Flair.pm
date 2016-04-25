package Scot::App::Flair;

use lib '../../../lib';

=head1 Name

Scot::App::Flair

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
use Scot::Util::Scot;
use Scot::Util::EntityExtractor;
use Scot::Util::ImgMunger;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
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

has imgmunger   => (
    is          => 'ro',
    isa         => 'Scot::Util::ImgMunger',
    required    => 1,
    lazy        => 1,
    builder     => '_get_img_munger',
);

sub _get_img_munger {
    my $self    = shift;
    return Scot::Util::ImgMunger->new({
        log => $self->env->log,
    });
};

has base_url    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default    => "/scot/api/v2",
);

has scot        => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    return Scot::Util::Scot->new();
}

sub run {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Starting STOMP watcher");

    my $pm  = AnyEvent::ForkManager->new(max_workers => 10);

    $pm->on_start( sub {
        my ($pm, $pid, $action, $type, $id) = @_;
        $log->debug("Starting worker $pid to handle $action on $type $id");
    });

    $pm->on_finish( sub {
        my ($pm, $pid, $status, $action, $type, $id) = @_;
        $log->debug("Ending worker $pid to handle $action on $type $id");
    });

    my $stomp   = new AnyEvent::STOMP::Client();

    $stomp->connect();

    $stomp->on_connected(
        sub {
            my $stomp    = shift;
            $stomp->subscribe('/topic/scot');
        }
    );

    my $scot    = $self->scot;

    $stomp->on_message(
        sub {
            my ($stomp, $header, $body) = @_;
            $log->debug("-"x50);
            $log->debug("header : ", { filter => \&Dumper, value => $header});
            $log->debug("body   : ", { filter => \&Dumper, value => $body});

            # read $body to determine alert or entry number
            my $json    = decode_json $body;
            $log->debug("body   : ", { filter => \&Dumper, value => $json});
            my $type    = $json->{data}->{type};
            my $id      = $json->{data}->{id};
            my $action  = $json->{action};

            if ( $action ne "created" and $action ne "updated" ) {
                $log->trace("not a created or updated action");
                return;
            }
            if ( $type ne "alert" and $type ne "entry" ) {
                $log->trace("non flairable creation/update");
                return;
            }


            $pm->start(
                cb  => sub {
                    my ($pm, $action, $type, $id) = @_;

                    my $record = $scot->get($type,$id);

# leaving until tested above line
                    #my $url     = $self->base_url . "/$type/$id";
                    #$log->debug("Getting $url");
                    # do a REST GET of that thing
                    #my $tx  = $scot->get($url);
                    # process through Entity Extractor
                    #my $record  = $tx->res->json;

                    $log->debug("GET Response: ", 
                                { filter => \&Dumper, value => $record });

                    if ( $record->{parsed} != 0 ) {
                        $log->debug("Already flaired!");
                        return;
                    }

                    if ( $type eq "alert" ) {
                        $self->process_alert($record);
                        return;
                    }
                    $self->process_entry($record);
                },
                args    => [ $action, $type, $id ],
            );
            $log->debug("-"x50);
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
    my $scot        = $self->scot;

    $log->trace("Processing Alert");

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


    # save via REST PUT
    my $url = $self->base_url."/alert/$record->{id}";
    my $tx  = $scot->put($url,{
        data_with_flair => $flair,
        entities        => \@entities,
        parsed          => 1,
    });
    $self->enrich_entities(\@entities);
}

sub process_entry {
    my $self    = shift;
    my $record  = shift;
    my $extractor   = $self->extractor;
    my $imgmunger   = $self->imgmunger;
    my $env         = $self->env;
    my $log         = $env->log;
    my $scot        = $self->scot;

    my $id  = $record->{id};

    $log->trace("Processing Entry $id");

    my $data    = $record->{body};
    $data       = $imgmunger->process_html($data, $id);

    my $eehref  = $extractor->process_html($data);

    my $url = $self->base_url."/entry/$id";

    my $json    = {
        parsed      => 1,
        body_plain  => $eehref->{text},
        body_flair  => $eehref->{flair},
        entities    => $eehref->{entities},
    };

    $log->debug("Putting: ", { filter => \&Dumper, value => $json});

    my $tx  = $scot->put($url, $json);
    $self->enrich_entities($eehref->{entities});
    
}

sub enrich_entities {
    my $self    = shift;
    my $aref    = shift;
    my $env     = $self->env;
    my %data    = ();   # hold all the enriching data

    my $enrichers   = $env->entity_enrichers;


    foreach my $entity (@$aref) {
        my $value   = $entity->{value};
        my $type    = $entity->{type};

        foreach my $ehref (@{$enrichers}) {
            my ($name,$href) = each %$ehref;
            if ( $href->{type} eq "native" ) {
                my $module = $href->{module};
                $data{$value}{$name} = $env->$module->get_data($type, $value);
            }
        }
    }

    # don't do this automatically, info lead potential 
    # Get VirusTotal if (domain, ipaddr, hash)
    
    return wantarray ? %data : \%data;
}
1;
