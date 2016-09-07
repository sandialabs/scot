package Scot::App::Flair2;

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

has env         => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    default     => sub { Scot::Env->instance },
);


has get_method  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'mongo',
);

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

has max_workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 20,
);

sub out {
    my $self    = shift;
    my $msg     = shift;

    if ( $self->interactive ) {
        say $msg;
    }
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $pm      = AnyEvent::ForkManager->new(max_workers => $self->max_workers);
    my $stomp   = AnyEvent::STOMP::Client->new();

    $stomp->connect();
    $stomp->on_connected(sub {
        my $s   = shift;
        $s->subscribe('/topic/scot');
        $self->out("---- subcribed to /topic/scot via STOMP ---");
        $log->debug("Subcribed to /topic/scot");
    });

    $pm->on_start(sub {
        my ($pm, $pid, $action, $type, $id) = @_;
        $self->out("------ Worker $pid handling $action on $type $id");
        $log->debug("Worker $pid handling $action on $type $id started");
    });

    $pm->on_finish(sub {
        my ($pm, $pid, $status, $action, $type, $id) = @_;
        $self->out("------ Worker $pid finished $action on $type $id: $status");
        $log->debug("Worker $pid handling $action on $type $id finished");
    });

    $pm->on_error(sub {
        $self->out("FORKMGR ERROR: ".Dumper(\@_));
    });


    $stomp->on_message(sub {
        my ($stomp, $header, $body) = @_;

        $log->debug("Header: ",{filter=>\&Dumper, value => $header});

        my $href = decode_json $body;
        $log->debug("Body: ",{filter=>\&Dumper, value => $href});

        my $action  = $href->{action};
        my $type    = $href->{data}->{type};
        my $id      = $href->{data}->{id};
        my $who     = $href->{data}->{who};
        $log->debug("STOMP: $action : $type : $id : $who");

        return if ($who eq "scot-flair");

        #$pm->start(
        #    cb      => sub {
        #        my ($pm, $action, $type, $id) = @_;
                $self->process_message($action, $type, $id);
        #    },
        #    args    => [ $action, $type, $id ],
        #);
        
    });

    my $cv  = AnyEvent->condvar;
    $cv->recv;

}

sub process_message {
    my $self    = shift;
    my $action  = shift;
    my $type    = shift;
    my $id      = shift;

    $self->log->debug("Processing Message: $action $type $id");

    if ( $action eq "created" or $action eq "updated" ) {
        if ( $type eq "alertgroup" ) {
            $self->process_alertgroup($id);
        }
        elsif ( $type eq "entry" ) {
            $self->process_entry($id);
        }
        else {
            $self->out("Non-processed type: $type");
        }
    } else {
        $self->out("action $action not processed");
    }
}

sub get_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $href;
    
    if ( $self->get_method eq "scot_api" ) {
        my $scot    = $self->scot;
        $href       = $scot->get({ type => "alertgroup/$id/alert" } );
    }
    else {
        my $mongo       = $self->env->mongo;
        my $collection  = $mongo->collection("Alertgroup");
        $href           = $collection->get_bundled_alertgroup($id);
    }
    return $href;
}

sub process_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $scot    = $self->scot;
    my @update  = ();
    my $log     = $self->log;

    $self->out("-------- processing alertgroup $id");

    $log->debug("asking scot for /alertgroup/$id/alert");

    my $alertgroup_href = $self->get_alertgroup($id);
    $log->debug("got",{filter=>\&Dumper, value=>$alertgroup_href});
    my $alerts_aref     = $alertgroup_href->{alerts};

    foreach my $record (@$alerts_aref) {
        my $newalert = $self->flair_record($record); 
        $log->debug("new alert: ",{filter=>\&Dumper, value=> $newalert});
        push @update, $newalert;
    }

    # build alergroup update href

    my $putdata = {
        id      => $id,
        type    => 'alertgroup',
        updated => time(),
        parsed  => 1,
        alerts  => \@update,
    };
    $log->debug("updating with ",{filter=>\&Dumper, value => $putdata});

    my $response = $self->update_alertgroup($putdata);

    $self->out("-------- done processing alertgroup $id");
    $log->debug("Done processing alertgroup $id");
}

sub update_alertgroup {
    my $self    = shift;
    my $putdata = shift;

    $self->log->debug("update alertgroup");

    if ( $self->get_method eq "scot_api" ) {
        my $response = $self->scot->put($putdata);
    }
    else {
        $self->log->debug("doing mongo update");
        my $agid       = $putdata->{id}; # this get blown away in agcol->
        my $mongo      = $self->env->mongo;
        my $agcol      = $mongo->collection("Alertgroup");
        $agcol->update_alertgroup_with_bundled_alert($putdata);
        $self->env->mq->send("scot", {
            action  => "updated",
            data    => {
                type    => "alertgroup",
                id      => $agid,
                who     => 'scot-flair',
            }
        });
    }
}

sub genspan {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;

    return  qq|<span class="entity $type" |.
            qq| data-entity-value="$value" |.
            qq| data-entity-type="$type">$value</span>|;
}

sub flair_record {
    my $self    = shift;
    my $record  = shift;
    my $extract = $self->extractor;
    my $log     = $self->log;
    my %flair   = ();   # ... the flaired text of the record
    my @entity  = ();   # ... the entity {value,type} found
    my %seen    = ();   # ... deduplication hash

    $log->debug("Flairing Alert $record->{id}");

    my $data    = $record->{data};
    
    COLUMN:
    foreach my $column (keys %{$data} ) {
        my $value   = $data->{$column};
        my $html    = '<html>'.encode_entities($value).'</html>';

        if ( $column =~ /^message_id$/i ) {
            # the data is telling us that this is a email message_id, so flair
            push @entity, { value => $value, type => "message_id" };
            $flair{$column}  = $self->genspan($value, "message_id");
            next COLUMN;
        }

        if ( $column =~ /^columns$/i ) {
            # no flairing on the "columns" attribute
            $flair{$column} = $value;
            next COLUMN;
        }

        my $extraction = $extract->process_html($html);

        $flair{$column} = $extraction->{flair};

        foreach my $entity_href (@{$extraction->{entities}}) {
            my $value   = $entity_href->{value};
            my $type    = $entity_href->{type};
            unless ( $seen{$value} ) {
                push @entity, $entity_href;
                $seen{$value}++;
            }
        }
    }
    return {
        id              => $record->{id},
        data_with_flair => \%flair,
        entities        => \@entity,
        parsed          => 1,
    };
}

sub get_entry {
    my $self    = shift;
    my $id      = shift;
    my $href;

    if ( $self->get_method eq "scot_api" ) {
        my $scot    = $self->scot;
        $href       = $scot->get({ id => $id, type => "entry" } );
    }
    else {
        my $mongo       = $self->env->mongo;
        my $collection  = $mongo->collection("Entry");
        my $entryobj    = $collection->find_iid($id);
        $href           = $entryobj->as_hash;
    }
    return $href;
}

sub process_entry {
    my $self    = shift;
    my $id      = shift;
    my $scot    = $self->scot;
    my $update;

    my $entry   = $self->get_entry($id);
    $update     = $self->flair_entry($entry, $id);

    my $putdata = {
        id      => 1,
        type    => 'entry',
        data    => {
            parsed      => 1,
            body_plain  => $update->{text},
            body_flair  => $update->{flair},
            entities    => $update->{entites},
        },
    };
    $self->update_entry($putdata);
    $self->out("-------- done processing entry $id");
}


sub update_entry {
    my $self    = shift;
    my $putdata = shift;

    $self->log->debug("updating entry");

    if ( $self->get_method eq "scot_api" ) {
        my $response = $self->scot->put($putdata);
    }
    else {
        my $mongo = $self->env->mongo;
        my $col   = $mongo->collection('Entry');
        my $obj   = $col->find_iid($putdata->{id});
        $obj->update({ '$set' => $putdata->{data} });
        $self->env->mq->send("scot", {
            action  => "updated",
            data    => {
                type    => "entry",
                id      => $obj->id,
                who     => 'scot-flair',
            }
        });
    }
}

sub flair_entry {
    my $self     = shift;
    my $entry_id = shift;
    my $extract  = $self->extractor;
    my $munger   = $self->imgmunger;

    $self->log->debug("flairing entry");

    my $href     = $self->get_entry($entry_id);
    my $body     = $href->{body};
    my $newbody  = $munger->process_html($body, $entry_id);
    my $flair    = $extract->process_html($newbody);
    return $flair;
}

1;
