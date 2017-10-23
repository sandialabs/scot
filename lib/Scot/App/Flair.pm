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
use Scot::Util::ScotClient;
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
    my $env     = $self->env;
    return $env->extractor;
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
    my $env     = $self->env;
    return $env->img_munger;
};

has stomp_host  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_host',
);

sub _build_stomp_host {
    my $self    = shift;
    my $attr    = "stomp_host";
    my $default = "localhost";
    my $envname = "scot_util_stomphost";
    return $self->get_config_value($attr, $default, $envname);
}
has stomp_port  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_port',
);

sub _build_stomp_port {
    my $self    = shift;
    my $attr    = "stomp_port";
    my $default = 61613;
    my $envname = "scot_util_stompport";
    return $self->get_config_value($attr, $default, $envname);
}

has interactive => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    default     => 0,
);

sub _build_interactive {
    my $self    = shift;
    my $attr    = "interactive";
    my $default = 0;
    my $envname = "scot_util_entityextractor_interactive";
    return $self->get_config_value($attr, $default, $envname);
}

has enrichers   => (
    is              => 'ro',
    isa             => 'Scot::Util::Enrichments',
    required        => 1,
    lazy            => 1,
    builder         => '_get_enrichers',
);

sub _get_enrichers {
    my $self    = shift;
    my $env     = $self->env;
    return $env->enrichments;
}

has max_workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_max_workers',
);

sub _build_max_workers {
    my $self    = shift;
    my $attr    = "max_workers";
    my $default = 20;
    my $envname = "scot_util_max_workers";
    return $self->get_config_value($attr, $default, $envname);
}

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
    my $stomp;

    if ( $self->stomp_host ne "localhost" ) {
        $stomp   = AnyEvent::STOMP::Client->new($self->stomp_host, $self->stomp_port);
    }
    else {
        $stomp = AnyEvent::STOMP::Client->new;
    }

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
        my $opts    = $href->{data}->{opts};
        $log->debug("STOMP: $action : $type : $id : $who : $opts");

        return if ($who eq "scot-flair");

        #$pm->start(
        #    cb      => sub {
        #        my ($pm, $action, $type, $id) = @_;
                $self->process_message($action, $type, $id, $opts);
        #    },
        #    args    => [ $action, $type, $id ],
        #);
        
    });

    my $cv  = AnyEvent->condvar;
    $cv->recv;

}

sub process_message {
    my $self    = shift;
    my $action  = lc(shift);
    my $type    = lc(shift);
    my $id      = shift;
    my $opts    = shift;

    $id += 0;

    $self->log->debug("Processing Message: $action $type $id");

    if ( $action eq "created" or $action eq "updated" ) {
        if ( $type eq "alertgroup" ) {
            $self->process_alertgroup($id,$opts);
            $self->put_stat("alertgroup flaired", 1);
        }
        elsif ( $type eq "entry" ) {
            $self->process_entry($id,$opts);
            $self->put_stat("entry flaired", 1);
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
#        my $scot    = $self->scot;
#        $href       = $scot->get({ type => "alertgroup/$id/alert" } );
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
    my $opts    = shift;
    my @update  = ();
    my $log     = $self->log;

    $self->out("-------- processing alertgroup $id");

    if (defined($opts) && $opts eq "noreflair") {
        $log->debug("noflair option received, short circuiting out...");
        return;
    }

    $log->debug("asking scot for /alertgroup/$id/alert");

    my $alertgroup_href = $self->get_alertgroup($id);
    $log->debug("Alerts in AG:",
                {filter=>\&Dumper, value=>$alertgroup_href->{alerts}});
    my $alerts_aref     = $alertgroup_href->{alerts};

    if ( ref($alerts_aref) ne "ARRAY" ) {
        $alerts_aref    = [ $alerts_aref ];
    }

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
#        my $response = $self->scot->put($putdata);
    }
    else {
        $self->log->debug("doing mongo update");
        my $agid       = $putdata->{id}; # this get blown away in agcol->
        my $mongo      = $self->env->mongo;
        my $agcol      = $mongo->collection("Alertgroup");
        $agcol->update_alertgroup_with_bundled_alert($putdata);
        $self->log->debug("after alertgroup update");
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

    $log->debug("    Alert data is ",{filter=>\&Dumper, value=>$data});
    
    COLUMN:
    foreach my $column (keys %{$data} ) {

        if ( $column eq "columns" ) {
            next COLUMN;
        }

        if (ref($data->{$column}) ne "ARRAY" ) {
            $log->error("WEIRD! $column is not an ARRAY is ",
                        {filter=>\&Dumper, value=>$data->{$column}});
            $data->{$column} = [ $data->{$column} ];
        }

        my @values   = @{ $data->{$column} };

        $log->debug("The cell has ".scalar(@values)." values in it");

        VALUE:
        foreach my $value (@values) {

            $log->debug("WORKING ON CELL VALUE $value");

            if ( $column =~ /^message[_-]id$/i ) {
                # the data is telling us that this is a email message_id, so flair
                $value =~ s/[\<\>//g;   # cut out the < > brackets if they exist
                my ($eref, $flair) = $self->process_cell($value, "message_id");
                if ( ! defined $seen{$eref->{value}} ) {
                    push @entity, $eref;
                    $seen{$eref->{value}}++;
                }
                $flair{$column} = $flair{$column} . "<br>" . $flair;
                $log->debug("Flair for $column is now ".$flair{$column});
                next VALUE;
            }
            if ( $column =~ /^(lb){0,1}scanid$/i ) {
                # another special column
                my ($eref, $flair) = $self->process_cell($value, "lb_scan_id");
                if ( ! defined $seen{$eref->{value}} ) {
                    push @entity, $eref;
                    $seen{$eref->{value}}++;
                }
                $flair{$column} = $flair{$column} . "<br>" . $flair;
                $log->debug("Flair for $column is now ".$flair{$column});
                next VALUE;
            }
            if ( $column =~ /^attachment[_-]name$/i  or 
                $column =~ /^attachments$/ ) {
                # each link in this field is a <div>filename</div>, 
                $log->debug("A File attachment Column detected!");
                $log->debug("value = ",{filter=>\&Dumper, value=>$value});
                
                if ( $value eq "" || $value eq " " ) {
                    next VALUE;
                }

                if ( $value eq "" || $value eq " " ) {
                    next VALUE;
                }
                
                my ($eref, $flair) = $self->process_cell($value, "filename");
                if ( ! defined $seen{$eref->{value}} ) {
                    push @entity, $eref;
                    $seen{$eref->{value}}++;
                }
                $flair{$column} = $flair{$column} . "<br>" . $flair;
                $log->debug("Flair for $column is now ".$flair{$column});
                next VALUE;
            }

            if ( $column =~ /urls\{\}/ ) {
                $log->debug("URLS column detected!");
            }

            if ( $column =~ /^columns$/i ) {
                # no flairing on the "columns" attribute
                $flair{$column} = $value;
                $log->debug("Flair for $column is now ".$flair{$column});
                next COLUMN;
            }

            my $html        = '<html>'.encode_entities($value).'</html>';
            my $extraction  = $extract->process_html($html);

            $log->debug("todds dumb code extracted: ",{filter=>\&Dumper, value=>$extraction});

            $flair{$column} = $flair{$column} . "<br>". $extraction->{flair};
            $log->debug("Flair for $column is now ".$flair{$column});

            foreach my $entity_href (@{$extraction->{entities}}) {
                my $value   = $entity_href->{value};
                my $type    = $entity_href->{type};
                unless ( $seen{$value} ) {
                    push @entity, $entity_href;
                    $seen{$value}++;
                }
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

sub process_cell {
    my $self    = shift;
    my $text    = shift;
    my $header  = shift;
    my $log     = $self->env->log;

    $log->debug("text   = $text");
    $text = encode_entities($text);
    $log->debug("encoded text   = $text");
    $log->debug("header = $header");
    my $flair   = $self->genspan($text,$header);
    $log->debug("text   = $text");
    $log->debug("header = $header");
    $log->debug("flair  = $flair");

    my $entity_href = { value => $text, type => $header };
    $log->debug("entity_href = ",{filter=>\&Dumper, value=>$entity_href});

    return $entity_href, $flair;

}

sub process_cell_x {
    my $self    = shift;
    my $cell    = shift; # html snippet, most likely <div style="white-space: pre-wrap;">foo</div>
    my $header  = shift; # the TH heading of this cell
    my $regex1  = qr{(div.*>)(.*?)(<\/div>)};
    my $regex2  = qr{div.*>(.*?)<\/div>};
    my $flair   = $cell;

    $flair          =~ s/$regex1/$1.$self->genspan($2).$3/ge;
    my @entities    =  map {
        { value => $_, type => $header }
    } ($cell =~ m/$regex2/g);

    return \@entities, $flair;
}

sub get_entry {
    my $self    = shift;
    my $id      = shift;
    my $href;
    $id  += 0;

    $self->log->debug("Getting entry $id");

    if ( $self->get_method eq "scot_api" ) {
#        my $scot    = $self->scot;
#        $href       = $scot->get({ id => $id, type => "entry" } );
    }
    else {
        my $mongo       = $self->env->mongo;
        my $collection  = $mongo->collection("Entry");
        my $entryobj    = $collection->find_iid($id);
        $href           = $entryobj->as_hash;
        $self->log->debug("Entry OBJ = ", {filter=>\&Dumper, value=>$href});
    }
    return $href;
}

sub process_entry {
    my $self    = shift;
    my $id      = shift;
#    my $scot    = $self->scot;
    my $update;
    my $log     = $self->log;

    $log->debug("initial grab of entry $id");
    my $entry   = $self->get_entry($id);
    $update     = $self->flair_entry($entry, $id);

    my $putdata = {
        id      => $id,
        type    => 'entry',
        data    => {
            parsed      => 1,
            body_plain  => $update->{text},
            body_flair  => $update->{flair},
            entities    => $update->{entities},
        },
    };
    $log->debug("Entry Put Data: ",{filter=>\&Dumper, value=>$putdata});
    $self->update_entry($putdata);
    $self->out("-------- done processing entry $id");
}


sub update_entry {
    my $self    = shift;
    my $putdata = shift;
    my $log     = $self->log;

    $log->debug("updating entry");

    if ( $self->get_method eq "scot_api" ) {
#        my $response = $self->scot->put($putdata);
    }
    else {
        my $id    = delete $putdata->{id};
        my $mongo = $self->env->mongo;
        my $col   = $mongo->collection('Entry');
        my $obj   = $col->find_iid($id);
        my $newdata = $putdata->{data};

        unless ($obj) {
            $log->error("failed to get object with id ".$id);
        }

        $self->log->debug("got object with id of ". $obj->id);
        $self->log->debug("putting entry: ",{filter=>\&Dumper,value=>$newdata});

        my $entity_aref = delete $newdata->{entities};

        if ( $obj->update({ '$set' => $newdata }) ){
            $self->log->debug("success updating");
            my $ohash = $obj->as_hash;
            $self->log->debug("hash is now: ",{filter=>\&Dumper, value=>$ohash});
        }
        else {
            $self->log->error("failed update, I think");
        }

        if ( defined($entity_aref) ) {
            if ( scalar(@$entity_aref) > 0 ) {
                my ($create_aref, $update_aref) = $mongo->collection('Entity')->update_entities($obj, $entity_aref);
                $log->debug("created entities: ",join(',',@$create_aref));
                foreach my $id (@$create_aref) {
                    $self->env->mq->send("scot", {
                        action  => "created",
                        data    => {
                            type    => "entity",
                            id      => $id,
                            who     => "scot-flair",
                        }
                    });
                }
                $self->put_stat("entity created", scalar(@$create_aref));
                $log->debug("updated entities: ",join(',',@$update_aref));
                foreach my $id (@$update_aref) {
                    $self->env->mq->send("scot", {
                        action  => "updated",
                        data    => {
                            type    => "entity",
                            id      => $id,
                            who     => "scot-flair",
                        }
                    });
                }
                $self->put_stat("entity updated", scalar(@$update_aref));
            }
        }

        $self->env->mq->send("scot", {
            action  => "updated",
            data    => {
                type    => "entry",
                id      => $id,
                who     => 'scot-flair',
            }
        });
    }
}

sub flair_entry {
    my $self       = shift;
    my $entry_href = shift;
    my $entry_id   = shift;
    my $extract    = $self->extractor;
    my $munger     = $self->imgmunger;
    my $log         = $self->log;

    $log->debug("flairing entry $entry_id");

    my $href     = $self->get_entry($entry_id);
    my $body     = $href->{body};
    my $newbody  = $body;   # default
    try {
        $newbody  = $munger->process_html($body, $entry_id);
    }
    catch {
        $log->error("Error in imgmunger process: $_");
    };
    my $flair    = $extract->process_html($newbody);
    $self->log->debug("flairing returned ",{filter=>\&Dumper, value=>$flair});
    return $flair;
}

1;
