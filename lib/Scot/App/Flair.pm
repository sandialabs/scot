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
use Scot::App;
use Scot::Util::Scot;
use Scot::Util::EntityExtractor;
use Scot::Util::ImgMunger;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use HTML::Entities;
use Module::Runtime qw(require_module);
use strict;
use warnings;
use v5.18;

use Moose;

extends 'Scot::App';

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
        log => $self->log,
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
        log => $self->log,
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
    say Dumper($self->config);
    return Scot::Util::Scot->new({
        log         => $self->log,
        servername  => $self->config->{scot}->{servername},
        username    => $self->config->{scot}->{username},
        password    => $self->config->{scot}->{password},
        authtype    => $self->config->{scot}->{authtype},
    });
}

has interactive => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    default     => 0,
);

has enrichers   => (
    is              => 'ro',
    isa             => 'ArrayRef',
    required        => 1,
    lazy            => 1,
    builder         => '_get_enrichers',
);

sub _get_enrichers {
    my $self    = shift;
    my @enrichers   = ();
    foreach my $href (@{$self->config->{entity_enrichers}}) {
        my ($name, $data) = each %$href;
        my $type    = $data->{type};
        my $module  = $data->{module};
        my $config  = $data->{config};
        
        if ( $type eq "native" ) {
            require_module($module);
            my $init    = {
                log     => $self->log,
            };

            if (defined $config){
                $init->{config} = $config;
            }
            push @enrichers, {
                $name   => $module->new($init),
            };
        }
        else {
            # TODO: put support for webservice here
            $self->log->warn("No support for webservice, YET!");
        }
    }
    return \@enrichers;
}

sub run {
    my $self    = shift;
    my $log     = $self->log;

    $log->debug("Starting STOMP watcher");
    $log->debug("Config is ",{filter=>\&Dumper,value=>$self->config});

    my $pm  = AnyEvent::ForkManager->new(max_workers => 10);

    $pm->on_start( sub {
        my ($pm, $pid, $action, $type, $id) = @_;
        $log->debug("Starting worker $pid to handle $action on $type $id");
    });

    $pm->on_finish( sub {
        my ($pm, $pid, $status, $action, $type, $id) = @_;
        $log->debug("Ending worker $pid to handle $action on $type $id");
    });

    $pm->on_error( sub {
        $log->error("Error encountered", {filter=>\&Dumper, value=>\@_});
    });

    my $stomp   = new AnyEvent::STOMP::Client();

    $stomp->connect();

    $stomp->on_connected(
        sub {
            my $stomp    = shift;
            $stomp->subscribe('/topic/scot');
            if ( $self->interactive ) {
                say "==== Listening via STOMP to /topic/scot =====";
            }
        }
    );

    my $scot    = $self->scot;

    $stomp->on_message(
        sub {
            my ($stomp, $header, $body) = @_;
            $log->debug("-"x50);
            $log->debug("Received STOMP Message");
            $log->debug("header : ", { filter => \&Dumper, value => $header});
            # $log->debug("body   : ", { filter => \&Dumper, value => $body});

            # read $body to determine alert or entry number
            my $json    = decode_json $body;
            $log->debug("body   : ", { filter => \&Dumper, value => $json});
            my $type    = $json->{data}->{type};
            my $id      = $json->{data}->{id};
            my $action  = $json->{action};

            if ( $self->interactive ) {
                say "---";
                say "--- $action message received";
                say "--- $type $id";
                say "---";
            }

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

                    $log->debug("Getting $type $id from SCOT");

                    my $record = $scot->get($type,$id);

                    if ( $self->interactive ) {
                        say "+ got $type $id from scot: ".
                            Dumper($record);
                    }

                    # leaving until tested above line
                    #my $url     = $self->base_url . "/$type/$id";
                    #$log->debug("Getting $url");
                    # do a REST GET of that thing
                    #my $tx  = $scot->get($url);
                    # process through Entity Extractor
                    #my $record  = $tx->res->json;

                    $log->debug("GET Response: ", 
                                { filter => \&Dumper, value => $record });

                    if ( defined($record->{parsed}) 
                         and $record->{parsed} != 0 ) {
                        $log->debug("Already flaired!");
                        return;
                    }

                    if ( $type eq "alert" ) {
                        $self->process_alert($record);
                        return;
                    }
                    $self->process_entry($record);
                    if ( $self->interactive ) {
                        say "   --- processed $type $id";
                    }
                },
                args    => [ $action, $type, $id ],
            );
            $log->debug("-"x50);
        }
    );

    my $cv  = AnyEvent->condvar;

    #$pm->wait_all_children(
    #    cb  => sub {
    #        my ($pm) = @_;
    #        $cv->send;
    #    },
    #);
    $cv->recv;
}

sub process_alert  {
    my $self        = shift;
    my $record      = shift;
    my $extractor   = $self->extractor;
    my $log         = $self->log;
    my $scot        = $self->scot;

    $log->trace("Processing Alert");

    if ( $self->interactive ) {
        $log->debug(" #### RECEIVED record ",{filter=>\&Dumper, value => $record});
        say "+ Received Record ".Dumper($record);
    }

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
            $flair->{$key} = qq|<span class="entity message_id" |.
                             qq| data-entity-value="$value" |.
                             qq| data-entity-type="message_id">$value</span>|;
            next TUPLE;
        }

        # note self on monday.  this isn't working find out why.
        my $eehref  = $extractor->process_html($encoded);
        $log->debug("HEY DUFUS: eehref = ",{filter=>\&Dumper, value=>$eehref});

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

    $log->debug(" #### record is ",{filter=>\&Dumper, value => $record});

    # save via REST PUT
    my $url = $self->base_url."/alert/".$record->{id};
    my $tx  = $scot->put('alert', $record->{id}, {
        data_with_flair => $flair,
        entities        => \@entities,
        parsed          => 1,
    });
    my $enriched = $self->enrich_entities(\@entities);
}

sub process_entry {
    my $self    = shift;
    my $record  = shift;
    my $extractor   = $self->extractor;
    my $imgmunger   = $self->imgmunger;
    my $log         = $self->log;
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
    my $enriched = $self->enrich_entities($eehref->{entities});
    
}

sub enrich_entities {
    my $self    = shift;
    my $aref    = shift;
    my $log     = $self->log;
    my %data    = ();   # hold all the enriching data

    my $enrichers   = $self->enrichers;


    foreach my $entity (@$aref) {
        my $value   = $entity->{value};
        my $type    = $entity->{type};

        foreach my $ehref (@{$enrichers}) {
            $log->debug("enricher: ",{filter=>\&Dumper, value=>$ehref});
            my ($name,$instance) = each %$ehref;
            unless (ref($instance)) {
                $log->debug("instance is unblessed! ",{filter=>\&Dumper, value=>$ehref});
            }
            $data{$value}{$name} = $instance->get_data($type, $value);
        }
    }

    # don't do this automatically, info lead potential 
    # Get VirusTotal if (domain, ipaddr, hash)
    
    return wantarray ? %data : \%data;
}

sub update_entities {

}

1;
