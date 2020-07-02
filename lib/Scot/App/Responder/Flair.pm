package Scot::App::Responder::Flair;

use Data::Dumper;
use SVG::Sparkline;
use HTML::Entities;
use Try::Tiny;
use Moose;
extends 'Scot::App::Responder';

has name    => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default => 'Flair',
);

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Extractor::Processor',
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

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $log     = $self->log;

    $log->trace("pm : ",{filter=>\&Dumper, value=>$pm});
    $log->debug("processing message: ",{filter=>\&Dumper, value=>$href});

    $log->debug("refreshing entitytypes");
    $self->env->regex->load_entitytypes;

    my $action  = lc($href->{action});
    my $type    = lc($href->{data}->{type});
    my $id      = $href->{data}->{id} + 0;
    my $who     = $href->{data}->{who};
    my $opts    = $href->{data}->{opts};

    $log->debug("[Wkr $$] Processing message $action $type $id from $who");

    if ( $who eq "scot-flair" ) {
        $log->debug("I guess I sent this message, skipping...");
        return "skipping self message";
    }

    if ( $action eq "created" or $action eq "updated" ) {
        $log->debug("--- $action message ---");
        if ( $type eq "alertgroup" ) {
            $self->process_alertgroup($id,$opts);
            $self->put_stat("alertgroup flaired", 1);
            return 1;
        }
        elsif ( $type eq "entry" ) {
            $self->process_entry($id,$opts);
            $self->put_stat("entry flaired", 1);
            return 1;
        }
        else {
            $log->error("Non processed type $type, skipping");
        }
    } else {
        $log->error("action $action not processed");
    }
}

sub get_alertgroup {
    my $self        = shift;
    my $id          = shift;
    my $mongo       = $self->env->mongo;
    my $collection  = $mongo->collection("Alertgroup");
    my $href        = $collection->get_bundled_alertgroup($id);
    return $href;
}

sub process_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $opts    = shift;
    my @update  = ();
    my $log     = $self->log;

    $log->debug("processing alertgroup $id");

    if (defined($opts) && $opts eq "noreflair") {
        $log->debug("noflair option received, short circuiting out...");
        return;
    }

    $log->debug("asking scot for /alertgroup/$id/alert");

    my $alertgroup_href = $self->get_alertgroup($id);

    $log->debug("Alerts in AG:", {filter=>\&Dumper, value=>$alertgroup_href->{alerts}});

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

    $log->debug("Done processing alertgroup $id");
}

sub update_alertgroup {
    my $self    = shift;
    my $putdata = shift;
    my $log     = $self->log;

    $log->debug("update alertgroup");

    if ( $self->get_method eq "scot_api" ) {
#        my $response = $self->scot->put($putdata);
    }
    else {
        $log->debug("doing mongo update");
        my $agid       = $putdata->{id}; # this get blown away in agcol->
        my $mongo      = $self->env->mongo;
        my $agcol      = $mongo->collection("Alertgroup");
        $agcol->update_alertgroup_with_bundled_alert($putdata);
        $log->debug("after alertgroup update");
        $self->env->mq->send("/topic/scot", {
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
            $log->warn("WEIRD! $column is not an ARRAY is ",
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
                $value =~ s/[\<\>]//g;   # cut out the < > brackets if they exist
                my ($eref, $flair) = $self->process_cell($value, "message_id");
                if ( ! defined $seen{$eref->{value}} ) {
                    push @entity, $eref;
                    $seen{$eref->{value}}++;
                }
                $flair{$column} = $self->append_flair($flair{$column}, $flair);
                $log->debug("Flair for $column is now ".$flair{$column});
                next VALUE;
            }
            if ( $column =~ /^(lb){0,1}scanid$/i ) {
                # another special column
                my ($eref, $flair) = $self->process_cell($value, "uuid1");
                if ( ! defined $seen{$eref->{value}} ) {
                    push @entity, $eref;
                    $seen{$eref->{value}}++;
                }
                $flair{$column} = $self->append_flair($flair{$column}, $flair);
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
                $flair{$column} = $self->append_flair($flair{$column}, $flair);
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

            if ( $column =~ /^sparkline$/i 
                 or grep {/__SPARKLINE__/} @values 
            ) {
                $log->debug("sparkline column detected!");
                my @sparkvalues = @values;
                $log->debug("sparkvalues: ",{filter=>\&Dumper, value=>\@sparkvalues});
                my $head = shift @sparkvalues;
                $log->debug("head is $head");
                if ($head eq "##__SPARKLINE__##" ) {
                    $log->debug("creating svg::sparkline");
                    my $svg = SVG::Sparkline->new( Line => { values =>\@sparkvalues, color => 'blue', height =>12 } );
                    $flair{$column} = $svg->to_string();
                    next COLUMN; # or VALUE?
                }
            }

            my $html        = '<html>'.encode_entities($value).'</html>';
            my $extraction  = $extract->process_html($html);

            $log->debug("todds dumb code extracted: ",{filter=>\&Dumper, value=>$extraction});

            $flair{$column} = $self->append_flair($flair{$column}, $extraction->{flair});
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

sub append_flair {
    my $self            = shift;
    my $existing_flair  = shift;
    my $new_flair       = shift;

    return $new_flair if (! defined $existing_flair);
    return $new_flair if ( $existing_flair eq '' );
    return $existing_flair . " " . $new_flair;
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
    $log->debug("-------- done processing entry $id");
}

sub merge_entity_data {
    my $self    = shift;
    my $old     = shift;
    my $new     = shift;
    my $merged  = {};

    # old data inserted first

    foreach my $key (keys %{$old}) {
        $merged->{$key} = $old->{$key};
    }

    # new data is added or overwrites old

    foreach my $key (keys %{$new}) {
        $merged->{$key} = $new->{$key};
    }

    return $merged;
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

        my $olddata = $obj->{data};

        $self->log->debug("got object with id of ". $obj->id);

        my $entity_aref = delete $newdata->{entities};
        my $user_aref   = delete $newdata->{userdef};

        my $merge_data  = $self->merge_entity_data($olddata, $newdata);

        $self->log->debug("putting entry: ",{filter=>\&Dumper,value=>$merge_data});

        if ( $obj->update({ '$set' => $merge_data }) ){
            $self->log->debug("success updating");
            my $ohash = $obj->as_hash;
            $self->log->debug("hash is now: ",{filter=>\&Dumper, value=>$ohash});
        }
        else {
            $self->log->error("failed update, I think");
        }

        my $ecol    = $mongo->collection('Entity');

        if ( defined($entity_aref) ) {
            if ( scalar(@$entity_aref) > 0 ) {
                my ( $create_aref, 
                     $update_aref) = $ecol->update_entities($obj, $entity_aref);
                $log->debug("created entities: ",join(',',@$create_aref));
                foreach my $id (@$create_aref) {
                    $self->env->mq->send("/topic/scot", {
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
                    $self->env->mq->send("/topic/scot", {
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
            else {
                $log->debug("no entities present");
            }
        }

        $self->env->mq->send("/topic/scot", {
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
