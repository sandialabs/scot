package Scot::App::Flair;

use lib '../../../lib';
use lib '/opt/scot/lib';

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
use Scot::Util::Scot2;
use Scot::Util::EntityExtractor;
use Scot::Util::ImgMunger;
use Scot::Util::Enrichments;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use HTML::Entities;
use Module::Runtime qw(require_module);
use Sys::Hostname;
use strict;
use warnings;
use v5.18;

use Moose;

extends 'Scot::App';

has thishostname    =>  (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { hostname; },
);

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

has scot        => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot2',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    # say Dumper($self->config);
    return Scot::Util::Scot2->new({
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
    isa             => 'Scot::Util::Enrichments',
    required        => 1,
    lazy            => 1,
    builder         => '_get_enrichers',
);

sub _get_enrichers {
    my $self            = shift;
    my $enrichconfig    = $self->config->{enrichments};
    $enrichconfig->{log} = $self->log;
    return Scot::Util::Enrichments->new($enrichconfig);
}

sub reprocess {
    my $self    = shift;
    my $time    = shift // 0;
    my $reparse = shift;
    $time += 0; # ensure number treatment not string
    my $log     = $self->log;
    my $scot    = $self->scot;
    #my $req     = {
    #    match   => {
    #        created    => { begin => $time, end => time() },
    #    }
    #};
    my $req = {
        type    => "alert",
        params  => {
            created => [ $time, time() ]
        }
    };
    unless ( $reparse ) {
        $req->{params}->{parsed} = 0;
    }

    $log->debug("match request is ",{filter=>\&Dumper, value=>$req});

    my $json    = $scot->get($req);

    foreach my $record (@{$json->{records}}) {
        $self->process_alert($record);
        if ( $self->interactive ) {
            say "Processed Alert ".$record->{id};
        }
    }
}


sub run {
    my $self    = shift;
    my $log     = $self->log;

    $log->debug("Starting STOMP watcher");
    # $log->debug("Config is ",{filter=>\&Dumper,value=>$self->config});

    my $pm  = AnyEvent::ForkManager->new(max_workers => 20);

    $pm->on_start( sub {
        my ($pm, $pid, $action, $type, $id) = @_;
        $log->debug("Starting worker $pid to handle $action on $type $id");
        say "~~~ Starting working $pid to handle $action on $type $id";
    });

    $pm->on_finish( sub {
        my ($pm, $pid, $status, $action, $type, $id) = @_;
        $log->debug("Ending worker $pid to handle $action on $type $id");
        say "~~~ Ending working $pid to handle $action on $type $id";
    });

    $pm->on_error( sub {
        $log->error("Error encountered", {filter=>\&Dumper, value=>\@_});
        say "!!!!!!! ERROR encountered !!!!!!";
        say Dumper(\@_);
    });

    my $stomp   = AnyEvent::STOMP::Client->new();

    my $subscribe_headers   = {
        id                          => $self->thishostname,
        'activemq.subscriptionName' => 'scot-queue',
    };

    my $connect_headers = {
        'client-id' => 'scot-queue',
    };

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

    my $myusername  = $self->config->{scot}->{username};

    $stomp->on_error(
        sub {
            $log->debug("STOMP Error: ", { filter =>\&Dumper, value => \@_ });
            say "STOMP ERROR: ".Dumper(\@_);
        }
    );

    $stomp->on_message(
        sub {
            my ($stomp, $header, $body) = @_;
            $log->debug("-"x50);
            $log->debug("Received STOMP Message");
            $log->debug("header : ", { filter => \&Dumper, value => $header});
            $log->debug("body   : ", { filter => \&Dumper, value => $body});

            # read $body to determine alert or entry number
            my $json    = decode_json $body;
            # $log->debug("body   : ", { filter => \&Dumper, value => $json});
            say "----------------- JSON Message -------------";
            say Dumper($json);
            say "----------------- ------------ -------------";
            
            my $type    = $json->{data}->{type};
            my $id      = $json->{data}->{id};
            my $who     = $json->{data}->{who};
            my $action  = $json->{action};

            if ( $self->interactive ) {
                say "---";
                say "--- $action message received";
                say "--- $type $id ($who)";
                say "---";
            }


            if ( $who eq $myusername ) {
                $log->debug("Message was result of this program, ignoring.");
                return;
            }

            if ( $action ne "created" and $action ne "updated" ) {
                $log->debug("not a created or updated action");
                return;
            }
            if ( $type ne "alertgroup" and $type ne "entry" ) {
                $log->debug("non flairable creation/update");
                return;
            }

            $pm->start(
                cb  => sub {
                    my ($pm, $action, $type, $id) = @_;
                    if ( $type eq "alertgroup") {
                        $self->process_alertgroup($id);
                    }
                    else {
                        $self->process_one($type, $id);
                    }
                },
                args    => [ $action, $type, $id ],
            );
            $log->debug("-"x50);
        }
    );
    my $cv  = AnyEvent->condvar;
    $cv->recv;
}

sub process_one {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $scot    = $self->scot;
    my $log     = $self->log;

    $log->debug("Getting $type $id from SCOT");
    say "=== Retrieving $type $id from SCOT";

    my $record = $scot->get({
        type    => $type,
        id      => $id
    });
    $log->debug("GET Response: ", 
                { filter => \&Dumper, value => $record });
    if ( defined($record) and ref($record) ne "HASH" ) {
        if ( $self->interactive ) {
            say "+++ got record from scot";
        }
        #if ( $record->{parsed} != 0 ) {
        #    $log->debug("Already flaired!");
        #    if ( $self->interactive ) {
        #        say "@@@ already flaired";
        #    }
        #    return;
        #}
    }
    else {
        if ( $self->interactive ) {
            say "failed to get a record!";
        }
        $log->error("failed to get a record from scot");
    }

    if ( $type eq "alert" ) {
        $self->process_alert($record);
        return;
    }
    $self->process_entry($record);
    if ( $self->interactive ) {
        say "--- processed $type $id";
        say "-"x80;
    }
}

sub process_alertgroup {
    my $self    = shift;
    my $agid    = shift;
    my $scot    = $self->scot;

    my $href    = $scot->get({
        type    => "alertgroup/$agid/alert"
    });
    my $alerts  = $href->{records};
    foreach my $alert (@$alerts) {
        $self->process_one("alert", $alert->{id});
    }
}

sub process_alert  {
    my $self        = shift;
    my $record      = shift;
    my $extractor   = $self->extractor;
    my $log         = $self->log;
    my $scot        = $self->scot;

    $log->debug("Processing Alert", {filter=>\&Dumper, value => $record});

    my $data    = $record->{data};
    my $flair;
    my @entities;
    my %seen;

    TUPLE:
    foreach my $key (keys %{$data}) {
        my $value   = $data->{$key};

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

        if ( $key =~ /^columns$/i ) {
            # columns do not need to be flaired, they are provided 
            # to the ui so that the ui can build a table
            $flair->{$key}  = $value;
            next TUPLE;
        }

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
    my $json_result = $scot->put({
        id      => $record->{id},
        type    => 'alert',
        data    => {
            data_with_flair => $flair,
            entities        => \@entities,
            parsed          => 1,
        },
    });
    # my $enriched = $self->enrich_entities(\@entities);
}

sub process_entry {
    my $self    = shift;
    my $record  = shift;
    my $extractor   = $self->extractor;
    my $imgmunger   = $self->imgmunger;
    my $log         = $self->log;
    my $scot        = $self->scot;

    my $id  = $record->{id};

    $log->debug("Processing Entry $id");

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

    my $json_result = $scot->put({
        id      => $record->{id}, 
        type    => "entry",
        data    => $json,
    });
    # my $enriched = $self->enrich_entities($eehref->{entities});
    
}

sub enrich_entities {
    my $self    = shift;
    my $aref    = shift;
    my $log     = $self->log;
    my %data    = ();   # hold all the enriching data

    my $enricher   = $self->enrichers;

    foreach my $entity (@$aref) {
        $data{$entity->{value}} = $enricher->enrich($entity, 1);
    }

    # don't do this automatically, info lead potential 
    # Get VirusTotal if (domain, ipaddr, hash)
    
    return wantarray ? %data : \%data;
}

sub update_entities {

}

1;
