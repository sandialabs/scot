package Scot::App::Migrate;

use lib '../../../lib';

=head1 Name

Scot::App::Migrate

=head1 Description

This controller will migrate a SCOT < 3.4 database
to a SCOT 3.5 database

=cut

use Scot::Env;
use Scot::App;
use Scot::Util::ElasticSearch;
use MongoDB;
use Data::Dumper;
use Try::Tiny;
use HTML::Entities;
use Time::HiRes qw(gettimeofday tv_interval);
use Safe::Isa;
use Storable;
use HTML::TreeBuilder;
use strict;
use warnings;


use Moose;
extends 'Scot::App';

has es => (
    is       => 'ro',
    isa      => 'Scot::Util::ElasticSearch',
    required => 1,
    lazy     => 1,
    builder  => '_get_es',
);

sub _get_es {
    my $self = shift;
    my $env  = $self->env;
    return $env->es;
}

has extractor   => (
    is       => 'ro',
    isa      => 'Scot::Extractor::Processor',
    required => 1,
    lazy     => 1,
    builder  => '_get_ee',
);

sub _get_ee {
    my $self    = shift;
    my $env     = $self->env;
    return $env->extractor;
}

has legacy_client   => (
    is       => 'rw',
    isa      => 'MongoDB::MongoClient',
    required => 1,
    lazy     => 1,
    builder  => '_get_connection',
);

sub _get_connection {
    my $self    = shift;
    return MongoDB->connect();
}

has legacydb    => (
    is          => 'rw',
    isa         => 'MongoDB::Database',
    required    => 1,
    lazy        => 1,
    builder     => '_get_legacy_db',
);

has legacy_db_name  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'scotng-prod',
);

sub _get_legacy_db {
    my $self    = shift;
    # return $self->legacy_client->get_database('scotng-prod');
    return MongoDB->connect->db('scotng-prod');
}

has default_read    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub { [ 'wg-scot-ir' ] },
);
has default_modify    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub { [ 'wg-scot-ir' ] },
);

has client  => (
    is          => 'rw',
    isa         => 'MongoDB::MongoClient',
    required    => 1,
    lazy        => 1,
    builder     => '_get_connection',
);

has db    => (
    is          => 'rw',
    isa         => 'MongoDB::Database',
    required    => 1,
    lazy        => 1,
    builder     => '_get_db',
);

has db_name  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'scot-prod',
);

sub _get_db {
    my $self    = shift;
    # return $self->legacy_client->get_database('scotng-prod');
    return MongoDB->connect->db($self->db_name);
}

sub migrate {
    my $self            = shift;
    my $new_col_type    = shift;                    # ... the collection name for the new collection
    my $new_col_name    = ucfirst($new_col_type);   # ... meerkat ucfirst version of $new_col_type
    my $opts            = shift;

    my $env = $self->env;
    my $log = $env->log;

    my $idfield = $self->lookup_idfield($new_col_type); # ... the old style integer id field in the old SCOT

    my $max_already_converted_id    = $self->get_max_id('new',$new_col_type);

    print "Max already converted id === $max_already_converted_id\n";

    my $legacy_colname      = $self->lookup_legacy_colname($new_col_type);
    my $legacy_collection   = $self->legacydb->get_collection($legacy_colname);
    my $findjson    = {};
    if (defined $idfield) {
        $findjson = {
            $idfield => { '$gt' => $max_already_converted_id }
        };
    }
    my $legacy_cursor       = $legacy_collection->find($findjson);
    $legacy_cursor->immortal(1);

    my $remaining_docs  = $legacy_collection->count($findjson);
    my $migrated_docs   = 0;
    my $total_docs      = $remaining_docs;
    my $total_time      = 0;
    my $running_timer   = $env->get_timer("running timer");

    print "$remaining_docs Remain to convert\n";

    ITEM:
    while ( my $item = $self->get_next_item($legacy_cursor) ) {

        if ( $item eq "skip" ) {
            $migrated_docs++;
            next ITEM;
        }

        my $timer   = $env->get_timer("[$new_col_name ". $item->{$idfield}."] Migration");

        if ( $opts->{verbose} ) {
            $self->output_pre_status($new_col_type, $idfield, $item);
        }

        unless ( $self->transform($new_col_type, $item) ) {
            $log->error("Error: $new_col_type Transform Failed! ", { filter => \&Dumper, value => $item } );
        }
        $remaining_docs--;
        my $elapsed = &$timer;
        $total_time += $elapsed;
        
        if ( $opts->{verbose} ) {
            my $stats   = $self->calculate_stats($new_col_type, $item, $elapsed, $remaining_docs);
            $self->output_post_status($new_col_type, $item, $stats,$running_timer,$migrated_docs);
        }
    }
    $self->update_last_id($new_col_type);
}

sub output_pre_status {
    my $self    = shift;
    my $type    = shift;
    my $idfield = shift;
    my $item    = shift;

    print "[$type ".$item->{$idfield}."] ";

    if ( $type eq "alertgroup" ) {
        my $alert_count = scalar(@{$item->{alert_ids}}) // 0;
        my $formatted   = sprintf("%15s", $alert_count);
        print "$formatted alerts to process\r";
    }
    if ( $type eq "entry" ) {
        my $formatted   = sprintf("%15s", length($item->{body}));
        print "$formatted characters in entry to convert\r";
    }
}

sub output_post_status {
    my $self    = shift;
    my $type    = shift;
    my $item    = shift;
    my $stats   = shift;
    my $rtimer  = shift;
    my $mdocs   = shift;

    print "[$type ";
    print $item->{id};
    print "] ";
    print $stats->{elapsed}. "secs - ";

    if ( $type eq "alertgroup" ) {
        my $format = sprintf("%5s", $stats->{alertcount});
        print "$format alerts - ";
    }
    if ( $type eq "entry" ) {
        my $format = sprintf("%7s", $stats->{length});
        print "$format characters - ";
    }
    print join(' ',$stats->{rate}, $stats->{eta}, $stats->{remain});

    my $time_so_far         = &$rtimer;
    if ( $time_so_far != 0 ) {
        my $avg_docs_per_sec    = $mdocs / $time_so_far;
        my $better_eta = 0;
        if ($avg_docs_per_sec != 0) {
            $better_eta = $stats->{remain} / $avg_docs_per_sec;
        }

        printf " [Avg rate: %5.3f] {ETA: %5.3f hours}",
                 $avg_docs_per_sec, $better_eta;
    }
    print "\n";
}

sub calculate_stats {
    my $self        = shift;
    my $type        = shift;
    my $item        = shift;
    my $etime       = shift;
    my $docsremain  = shift;

    my $rate    = 0;
    my $eta     = 9999999999;

    if ( $etime > 0 ) {
        $rate = ( 1 / $etime );
    }
    if ( $rate > 0 ) {
        $eta    = ( $docsremain / $rate )/3600;
    }

    my $href = {
        rate    => sprintf("%16s", sprintf("%5.3f docs/sec",$rate)),
        eta     => sprintf("%16s", sprintf("%5.3f hours", $eta)),
        remain  => $self->commify($docsremain),
        elapsed => sprintf("%5.2f", $etime),
    };

    if ( $type eq "alertgroup" ) {
        $href->{alertcount} = scalar(@{$item->{alert_ids}});
    }
    if ( $type eq "entry" ) {
        $href->{length} = length($item->{body});
    }
    return $href;
}

sub get_next_item {
    my $self    = shift;
    my $cursor  = shift;
    my $log     = $self->env->log;

    $log->trace("Fetching Next Item");
    my $item;
    try {
        $item   = $cursor->next;
    }
    catch {
        $log->error("Error fetching next item: $_");
        print "Error retrieving item: $_, skipping...\n";
        return "skip";
    };
    return $item;
}

sub get_max_id {
    my $self    = shift;
    my $type    = shift;    # new or legacy
    my $col     = shift;
    my $db      = ($type eq "legacy") ? 'legacydb' : 'db';
    my $nc      = $self->$db->get_collection($col);
    my $idfield = ($type eq "legacy") ? $self->lookup_idfield($col) : 'id';
    my $cursor  = $nc->find();
    unless (defined $idfield) {
        return 0;
    }
    $cursor->sort({$idfield => -1});
    my $doc     = $cursor->next;
    unless ($doc) {
        $self->env->log->error("Unable to find max $idfield in $col");
        return 0;
    }
    return $doc->{$idfield};
}

sub update_last_id {
    my $self    = shift;
    my $type    = shift;
    my $next_id_col = $self->db->get_collection('nextid');
    my $target_col  = $self->db->get_collection($type);

    my $max_id  = $self->get_max_id('new',$type);

    $next_id_col->update_one(
        { for_collection => $type }, 
        { '$set'  => { last_id => $max_id } }
    );
}

sub has_been_migrated {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->env->log;
    my $newcol  = $self->db->get_collection($type);
    my $newitem = $newcol->find_one({id => $id});

    if ( $newitem ) {
        $log->debug("[$type $id] Already migrated...");
        return 1;
    }
    return undef;
}

has idgen => (
    is      => 'rw',
    isa     => 'Int',
    required    => 1,
    default     => 1,
);

sub get_id  {
    my $self    = shift;
    my $id      = $self->idgen;
    $self->idgen($id++);
    return $id;
}

sub transform {
    my $self    = shift;
    my $type    = shift;    # ... the type of the new scot collection
    my $item    = shift;    # ... the href of the thing to convert
    my $env     = $self->env;
    my $log     = $env->log;

    my $method  = "xform_". $type;  # ... call this sub to do the transform
    my $idfield = delete $item->{idfield} // $self->lookup_idfield($type); # ... where is the int id
    my $id;
    unless ( defined $idfield ) {
        $id = $self->get_id;
    }
    else {
        $id      = delete $item->{$idfield};
    }
    $item->{id} = $id // '';    # ... stuff the id into the id field

    if ( $self->has_been_migrated($type, $id) ) {
        return 1;
    }

    $self->xform_permissions($item);
    $self->remove_unneeded($type, $item);
    return $self->$method($item);
}

sub xform_permissions {
    my $self    = shift;
    my $href    = shift;

    if ( $href->{readgroups} ) {
        $href->{groups} = {
            read    => delete $href->{readgroups} // $self->default_read,
            modify  => delete $href->{modifygroups} // $self->defautl_modify,
        };
    }
}

sub remove_unneeded {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    my $log     = $self->env->log;

    $log->trace("[$type ".$href->{id}."] removing un-needed fields");
    foreach my $attr ( @{ $self->get_unneeded_fields($type) } ) {
        delete $href->{$attr};
    }
}

sub xform_alertgroup {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};  # ... set in transform

    $log->trace("[Alertgroup $id] Transformation");

    my $new_ag_col      = $self->db->get_collection('alertgroup');
    my $new_alert_col   = $self->db->get_collection('alert');
    my $leg_alert_col   = $self->legacydb->get_collection('alerts');

    my @links;
    my @history = map { 
            {alertgroup => $id, history => $_ }
        } @{ delete $href->{history} // [] }; # ... history is in new collection
    my @tags    = map {
            {alertgroup => $id, tag => { value => $_ }}
        } @{ $href->{tags} // [] };  # ... tags are in new collection
    my @sources = map {
            {alertgroup => $id, source => { value => $_ }}
        } @{ delete $href->{sources} // [] };   # ... sources are pulled to new collection
    if ( $href->{source} ) {
        # some confusion over source vs. sources in various iteration of database
        push @sources, {alertgroup => $id, source => { value => $href->{source} } };
    }

    # force the new source array
    my @newsources = map { $_->{source}->{value} } @sources;
    $href->{source} = \@newsources;
    $href->{tag}    = delete $href->{tags};
    $href->{body}   = delete $href->{body_html};    # ...renaming
    $href->{view_history} = delete $href->{viewed_by}; 


    my $legacy_alert_cursor = $leg_alert_col->find({alertgroup => $id});
    $legacy_alert_cursor->immortal(1);
    $href->{alert_count} = $leg_alert_col->count({alertgroup => $id});

    my $entities;           # ... keep track of entities found
    my @alert_promotions;   # ... and promoted alerts
    my %status;             # ... keep track of status counts for alertgroup
    my @allentities;        # ... all entities found in alertgroup
    my $es  = $self->es;    # ... pump it into elastic

    ALERT:
    while ( my $alert = $legacy_alert_cursor->next ) {
        my $alertid = delete $alert->{alert_id};
        $alert->{id} = $alertid;
        die "No AlertID!" unless (defined $alertid);

        if ( defined($alert->{promotion_id}) and $alert->{promotion_id} > 0 ) {
            $status{promoted}++;
            $alert->{status} = "promoted";
        }
        else {
            $status{ $alert->{status} }++;
        }

        $self->remove_unneeded('alert', $alert);

        if ( $alert->{updated} ) {
            $alert->{updated}   = int($alert->{updated});
        }

        $self->xform_permissions($alert);

        my @alerthistory = map { 
                { alert => $alertid, history => $_ } 
            } @{ delete $alert->{history} // [] };
        push @history, @alerthistory;

        ( $alert->{data_with_flair}, $entities ) = $self->flair_alert_data($alert);

        if ( defined($entities) and ref($entities) eq "ARRAY" ) {
            push @allentities, @{$entities};
        }

        unless ( $alert->{data_with_flair} ) {
            $alert->{data_with_flair} = $alert->{data}; # punt
        }
        
        my @events = @{ delete $alert->{events} // [] };
        if ( scalar(@events) > 0 ) {
            $alert->{promotion_id} = pop @events;
        }
        else {
            $alert->{promotion_id} = 0;
        }

        $new_alert_col->insert_one($alert);
        # $es->index("alert", $alert);
    }

    $self->get_ag_status($href, \%status);

    $new_ag_col->insert_one($href);

    push @links, $self->create_history(@history);
    push @links, $self->create_sources(@sources);
    push @links, $self->create_tags(@tags);
    push @links, $self->create_entities(\@allentities);
    $self->create_links(@links);
    return 1;
}

sub get_ag_status {
    my $self    = shift;
    my $ag      = shift;
    my $shref   = shift;

    no warnings qw(uninitialized);

    $ag->{open_count}   = $shref->{open} // 0;
    $ag->{closed_count} = $shref->{closed} // 0;
    $ag->{promoted_count} = $shref->{promoted} // 0;

    if ( $shref->{promoteod} > 0 ) {
        $ag->{status} = "promoted";
    }
    elsif ( $shref->{open} > 0 ) {
        $ag->{status} = "open";
    }
    else {
        $ag->{status} = "closed";
    }
    use warnings qw(uninitialized);
}

sub xform_entry {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->trace("[Entry $id] Transformation");

    if ( length($href->{body}) > 2000000 ) {
        $log->warn("[Entry $id] HUGE body! Skipping...");
        $self->handle_huge_entry($href);
        return undef;
    }

    if ( ref($href->{body}) eq "MongoDB::BSON::Binary" ) {
        $href->{body} = '<html>'.$href->{plaintext}.'</html>';
    }

    my $entities;

    ( $href->{body_flair},
      $href->{body_plain},
      $entities )   = $self->flair_entry_data($href);

    $href->{parent}     = 0 unless ($href->{parent});
    $href->{owner}      = 'unknown' unless ($href->{owner});
    # this must be after the flairing bc flairing looks for target_type/id
    $href->{target}     = {
        type        => delete $href->{target_type},
        id          => delete $href->{target_id},
    };

    my @history = map {
        { entry => $id, history => $_ }
    } @{ delete $href->{history} //[] };

    my $ttype   = $href->{target}->{type};

    $href->{summary} = $self->is_summary($href);

    my $col = $self->db->get_collection('entry');
    $col->insert_one($href);
    # $self->es->index("entry", $href);
    my   @links;
    push @links, $self->create_history(@history);
    push @links, $self->create_entities($entities);
    $self->create_links(@links);
    $self->update_target_entry_count($href->{target});
    return 1;
}

sub update_target_entry_count {
    my $self    = shift;
    my $t       = shift;
    my $id      = $t->{id};
    my $type    = $t->{type};
    my $tcol    = $self->db->get_collection($type);
    $tcol->update_one( { id  => $id },
            {
                '$inc'  => {
                    entry_count => 1,
                },
            },
    );
}

sub is_summary {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;

    $log->debug("Checking if Entry $href->{id} is a Summary");

    my $target_type = $href->{target}->{type};
    my $target_id   = $href->{target}->{id};

    if ( $target_type ne "event" ) {
        $log->warn("Target of entry is not an event.");
        return 0;
    }

    my $col = $self->legacydb->get_collection('events');
    my $obj = $col->find_one({ event_id => $target_id });

    if ( $obj ) {
        $log->trace("Found the target event");
        if ( $obj->{summary_entry_id} ) {
            $log->trace("summary entry id is ".$obj->{summary_entry_id});
            if ( $obj->{summary_entry_id} == $href->{id} ) {
                $log->trace("yes this is a summary");
                return 1;
            }
            $log->trace("not a summary");
        }
        $log->trace("no summary_entry_id!");
    }
    $log->trace("target event not found!");
    return 0;
}

sub xform_event {
    my $self    = shift;
    my $col     = $self->db->get_collection('event');
    my $href    = shift;
    my $verbose = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->trace("[Event $id] transformation");

    my @links;

    $href->{promoted_from} = delete $href->{alerts} // [];
    if ( defined $href->{incident}) {
        $href->{promotion_id}  = pop @{delete $href->{incident}} // 0;
    }
    else {
        $href->{promotion_id}   = 0;
    }

    my @history = map {
        { event => $id, history => $_ }
    } @{ delete $href->{history} //[] };
    my @tags    = map {
        { event => $id, tag => { value => $_ } }   
    } @{ $href->{tags} //[] };
    my @sources = map {
        { event => $id, source => { value => $_, } }
    } @{ $href->{sources} //[] };

    $href->{source} = delete $href->{sources};
    $href->{views}  = delete $href->{view_count};
    $href->{tag}    = delete $href->{tags};

    $col->insert_one($href);

    push @links, $self->create_history(@history);
    push @links, $self->create_sources(@sources);
    push @links, $self->create_tags(@tags);
    $self->create_links(@links);

    return 1;

}

sub xform_incident {
    my $self    = shift;
    my $col     = $self->db->get_collection('incident');
    my $href    = shift;
    my $verbose = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $id      = $href->{id};

    $log->trace("[Incident $id] transformation ");

    my @links;
    $href->{promoted_from} = delete $href->{events} // [];

    unless ( defined $href->{owner} ) {
        $href->{owner} = "unknown";
    }

    my @history = map {
        { incident => $id, history => $_ }
    } @{ delete $href->{history} //[] };

    my @tags    = map {
        { incident => $id, tag => { value => $_ } }   
    } @{ $href->{tags} //[] };

    my @sources = map {
        { incident => $id, source => { value => $_, } }
    } @{ $href->{sources} //[] };

    $href->{source} = delete $href->{sources};
    $href->{tag} = delete $href->{tags};
    $col->insert_one($href);

    push @links, $self->create_history(@history);
    push @links, $self->create_sources(@sources);
    push @links, $self->create_tags(@tags);
    $self->create_links(@links);

    return 1;
}

sub xform_handler {
    my $self    = shift;
    my $col     = $self->db->get_collection('handler');
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $start   = delete $href->{date};
    my $end     = DateTime->new(
        year    => $start->year,
        month   => $start->month,
        day     => $start->day,
        hour    => 23,
        minute  => 59,
        second  => 59,
        time_zone => "Etc/UTC",
    );

    my $name            = delete $href->{user};
    $href->{start}      = $start->epoch;
    $href->{end}        = $end->epoch;
    $href->{username}   = $name;
    delete $href->{groups};

    $col->insert_one($href);
    return 1;
}

sub xform_file {
    my $self    = shift;
    my $col     = $self->db->get_collection('file');
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my @links   = ();

    $href->{directory} = delete $href->{dir};
    $href->{target}     = {
        type    => delete $href->{target_type},
        id      => delete $href->{target_id},
    };
    $href->{entry}  = delete $href->{entry_id};

    $col->insert_one($href);
    return 1;
}

sub xform_user {
    my $self    = shift;
    my $col     = $self->db->get_collection('user');
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    delete $href->{groups};
    if ( $href->{hash} ) {
        $href->{pwhash} = delete $href->{hash};
    }
    $href->{last_login_attempt} = $href->{lastvisit};

    $col->insert_one($href);
    return 1;
}

sub xform_guide {
    my $self    = shift;
    my $col     = $self->db->get_collection('guide');
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $guide   = delete $href->{guide};
    $href->{applies_to} = [ $guide ];

    $col->insert_one($href);
    return 1;
}

sub create_links {
    my $self      = shift;
    my @links     = @_;
    my $linkcol   = $self->db->get_collection('link');
    my $appearcol = $self->db->get_collection('appearance');
    my $env       = $self->env;
    my $log       = $env->log;

    return if (scalar(@links) < 1);

    my $timer   = $env->get_timer("[Links] Bulk created ");

    my $bulklink    = $linkcol->initialize_unordered_bulk_op;
    my $bulkappear  = $appearcol->initialize_unordered_bulk_op;

    my @l_links = ();
    my @a_links = ();

    foreach my $href (@links) {
        my ($k,$data)   = each %$href;
        if ( $k eq "link" ) {
            push @l_links, $data;
        }
        elsif ( $k eq "appearance" ) {
            push @a_links, $data;
        }
        else {
            $log->error("ERROR: unknown link type!");
        }
    }

    foreach my $d (@l_links) {
        $d->{id} = $self->get_next_id('link');
        $bulklink->insert_one($d);
    }

    my $result = try {
        $bulklink->execute;
    }
    catch {
        if ( $_->isa("MongoDB::WriteConcernError") ) {
            warn "Write concern failed";
        }
        else {
            $log->error("Error: (link) $_");
        }
    };
    
    foreach my $d (@a_links) {
        $d->{id}    = $self->get_next_id('appearance');
        $bulkappear->insert_one($d);
    }

    $result = try {
        $bulkappear->execute;
    }
    catch {
        if ( $_->isa("MongoDB::WriteConcernError") ) {
            warn "Write concern failed";
        }
        else {
            $log->error("Error: (appearance) $_");
        }
    };
    &$timer;
}

sub create_history {
    my $self    = shift;
    my @history = @_;
    my $env     = $self->env;
    my $log     = $env->log;
    my $col     = $self->db->get_collection('history');
    my $timer   = $env->get_timer("[history] Bulk created ");
    my $bulk    = $col->initialize_unordered_bulk_op;
    my @links   = ();

    return () if (scalar(@history) < 1);

    foreach my $h (@history) {
        my $data;
        my $type;
        my $id;
        foreach my $k (keys %$h) {
            if ($k eq "history") {
                $data = $h->{$k};
            }
            else {
                $type   = $k;
                $id     = $h->{$k};
            }
        }

        $data->{id}     = $self->get_next_id('history');
        $data->{when}   = int($data->{when});
        $data->{target} = { type    => $type, id => $id };
        $bulk->insert_one($data);
    }
    my $result = try {
        $bulk->execute;
    }
    catch {
        if ( $_->isa("MongoDB::WriteConcernError") ) {
            warn "Write concern failed";
        }
        else {
            $log->error("Error: $_");
        }
    };
    &$timer;
    return @links;
}

sub create_sources {
    my $self    = shift;
    my @sources = @_;
    my $env         = $self->env;
    my $log         = $env->log;
    my $col         = $self->db->get_collection('source');
    my $timer       = $env->get_timer("[source] Bulk create");
    my $bulk        = $col->initialize_unordered_bulk_op;
    my @links       = ();
    my $insertions  = 0;

    return () if (scalar(@sources) < 1);

    foreach my $h (@sources) {
        my ($data, $type, $id );
        foreach my $k (keys %$h) {
            if ( $k eq "source" ) {
                $data = $h->{$k};
            }
            else {
                $type   = $k;
                $id     = $h->{$k};
            }
        }
        if ( ref($data) eq "ARRAY" ) {
            $data = pop @{$data};
        }
        
        my $docid = 0;  # keeps moose from blowing up
        my $doc = $col->find_one({ value => $data->{value} });

        unless ($doc) {
            $docid  = $self->get_next_id('source');
            $data->{id} = $docid;
            $bulk->insert_one($data);
            $insertions++;
        }
        else {
            if ( $doc->{id} > 0 ) {
                $docid  = $doc->{id};
            }
        }

        push @links, {
            appearance  => {
                type    => 'source',
                apid    => $docid,
                value   => $data->{value},
                when    => 1,
                target  => { type => $type, id => $id },
            },
        };
    }

    if ( $insertions > 0 ) {
        my $result = try {
            $bulk->execute;
        }
        catch {
            if ( $_->isa("MongoDB::WriteConcernError") ) {
                warn "Write concern failed";
            }
            else {
                $log->error("Error Inserting Bulk Sources: $_.  Data =", 
                            {filter=>\&Dumper,value=>\@sources});
            }
        };
    }
    &$timer;
    return @links;
}

sub create_tags {
    my $self    = shift;
    my @tags    = @_;
    my $env         = $self->env;
    my $log         = $env->log;
    my $col         = $self->db->get_collection('tag');
    my $timer       = $env->get_timer("[tag] Bulk create");
    my $bulk        = $col->initialize_unordered_bulk_op;
    my @links       = ();
    my $insertions  = 0;

    return () if (scalar(@tags) < 1);

    foreach my $h (@tags) {
        my ($data, $type, $id );
        foreach my $k (keys %$h) {
            if ( $k eq "tag" ) {
                $data = $h->{$k};
            }
            else {
                $type   = $k;
                $id     = $h->{$k};
            }
        }
        if ( ref($data) eq "ARRAY" ) {
            $data = pop @{$data};
        }

        my $docid;
        my $doc = $col->find_one({ value => $data->{value} });
        unless ( $doc ) {
            $docid  = $self->get_next_id('tag');
            $data->{id} = $docid;
            $bulk->insert_one($data);
            $insertions++;
        }
        else {
            $docid  = $doc->{id};
        }
        push @links, {
            appearance  => {
                type    => 'tag',
                apid    => $docid,
                value   => $data->{value},
                when    => 1,
                target  => { type => $type, id => $id },
            },
        };
    }
    if ( $insertions > 0) {
        my $result = try {
            $bulk->execute;
        }
        catch {
            if ( $_->isa("MongoDB::WriteConcernError") ) {
                warn "Write concern failed";
            }
            else {
                $log->error("Error: $_");
            }
        };
    }
    &$timer;
    return @links;

}

sub create_entities {
    my $self        = shift;
    my $entities    = shift; # should be array ref
    my $env         = $self->env;
    my $log         = $env->log;
    my @links       = ();
    my $insertions  = 0;

    # $log->debug("entities are ",{filter=>\&Dumper, value=>$entities});

    return () unless ( defined $entities );
    return () if ( scalar(@$entities) < 1 );


    my $timer   = $env->get_timer("[Entities] Create Time");

    my $col     = $self->db->get_collection('entity');
    my $bulk    = $col->initialize_unordered_bulk_op;

    foreach my $entity (@{ $entities }) {
        my $id;
        my $existing = $col->find_one({
            value   => $entity->{value},
            type    => $entity->{type},
        });
        unless ( $existing ) {
            $entity->{id}   = $self->get_next_id('entity');
            my $res = $bulk->insert_one($entity);
            $id = $entity->{id};
            $insertions++;
        }
        else {
            $id = $existing->{id};
        }

        my @targets = @{delete $entity->{targets} };

        foreach my $href ( @targets ) {
            my $tid     = $href->{id};
            my $ttype   = $href->{type};

            my $link    = {
                link    => {
                    when    => $entity->{when},
                    value   => $entity->{value},
                    entity_id   => $id,
                    target  => {
                        type    => $ttype,
                        id      => $tid,
                    }
                }
            };
            push @links, $link;
        }
    }
    if ( $insertions > 0 ) {
        my $result = try {
            $bulk->execute;
        }
        catch {
            if ( $_->isa("MongoDB::WriteConcernError") ) {
                warn "Write concern failed";
            }
            else {
                $log->error("Error: $_");
            }
        };
    }
    my $elapsed = &$timer;
    return @links;
}


sub commify {
    my $self    = shift;
    my $number  = shift;
    my $text    = reverse $number;
    $text       =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

sub flair_alert_data {
    my $self    = shift;
    my $alert   = shift;
    my $id      = $alert->{id} // $alert->{alert_id};
    my $data    = $alert->{data};
    my @entities    = ();
    my %flair;
    my %seen;
    my $when    = $alert->{when} // $alert->{create};
    my $env     = $self->env;
    my $log     = $env->log;

    die "unknown alert id! ".Dumper($alert) unless ($id);

    # $log->debug("flairing: ",{filter=>\&Dumper, value=>$alert});
    $log->trace("[Alert $id] Flairing: ");

    my $timer = $self->env->get_timer("[Alert $id] Flair");

    TUPLE:
    while ( my ($key, $value) = each %{$data} ) {
        unless ( $value ) {
            # $log->warn("[Alert $id] ERROR Key $key with no Value!");
            next TUPLE;
        }
        if ( $key eq "columns" ) {
            # columns are not flaired 
            $flair{$key} = $value;
            next TUPLE;
        }
        my $encoded = '<html>' . encode_entities($value) . '</html>';
        if ( $key =~ /^message_id$/i ) {
            push @entities, { 
                value   => $self->strip_flair($value), 
                type    => "message_id" ,
                targets    => [
                    {   type => 'alert', id => $id },
                    {   type => 'alertgroup', id => $alert->{alertgroup} },
                ],
            };
            $flair{$key} = qq|<span class="entity message_id" |.
                             qq| data-entity-value="$value" |.
                             qq| data-entity-type="message_id">$value</span>|;
            next TUPLE;
        }

        my $href    = $self->extractor->process_html($encoded);
        $flair{$key}    = $href->{flair};

        foreach my $entityhref ( @{$href->{entities}} ) {
            my $v   = $entityhref->{value};
            my $t   = $entityhref->{type};
            $entityhref->{when} = $when;
            $entityhref->{targets} = [
                { type => 'alert', id => $id },
                { type => 'alertgroup', id => $alert->{alertgroup} },
            ];
            unless ( defined $seen{$v} ) {
                push @entities, $entityhref;
                $seen{$v}++;
            }
        }
    }
    my $flairsize = length( Dumper(\%flair) );
    my $elapsed = &$timer;
    if ($flairsize > 1000000) {
        $self->env->log->error("[Alert $id] ERROR flair command is too large");
        return;
    }
    # $log->debug("Found ".scalar(@entities). " entities", {filter=>\&Dumper, value=>\@entities});
    # $log->debug("Flair is ",{filter=>\&Dumper, value=>\%flair});
    return \%flair, \@entities;
}

sub flair_entry_data {
    my $self    = shift;
    my $href    = shift;
    my $id      = $href->{id} // $href->{entry_id};
    my $env     = $self->env;
    my $log     = $env->log;
    my @entities    = ();
    my %flair       = ();
    my %seen        = ();
    my $when        = $href->{when} // $href->{create};
    
    my $timer   = $env->get_timer("[Entry $id] Flair");
    my $flair   = $self->extractor->process_html($href->{body});

    foreach my $entityhref (@{$flair->{entities}}) {
        $entityhref->{when}     = $when;
        $entityhref->{targets}  = [
            { type => 'entry', id => $id },
            { type => $href->{target_type}, id => $href->{target_id} },
        ];
        unless ( defined $seen{$entityhref->{value}} ) {
            push @entities, $entityhref;
            $seen{$entityhref->{value}}++;
        }
    }

    my $elapsed = &$timer;
    return $flair->{flair}, $flair->{text}, \@entities;
}


sub strip_flair {
    my $self    = shift;
    my $flaired = shift;
    my $tree    = HTML::TreeBuilder->new();
       $tree->parse_content($flaired);

    my $element = $tree->look_down( _tag => 'span' );
    return '' unless (defined $element);
    return $element->as_trimmed_text;
}

sub get_next_id {
    my $self        = shift;
    my $collection  = shift;
    my %command;
    my $tie         = tie(%command, "Tie::IxHash");
    %command        = (
        findAndModify   => "nextid",
        query           => { for_collection => $collection },
        update          => { '$inc' => { last_id => 1 } },
        'new'           => 1,
        upsert          => 1,
    );

    my $output  = $self->db->run_command(\%command);
    my $id      = $output->{value}->{last_id};
    return $id;
}

sub lookup_idfield {
    my $self        = shift;
    my $collection  = shift;
    my %map         = (
        alert       => "alert_id",
        alertgroup   => "alertgroup_id",
        event       => "event_id",
        entry       => "entry_id",
        incident    => "incident_id",
        guide       => "guide_id",
        user        => "user_id",
        file        => "file_id",
        handler     => undef,
    );

    return $map{$collection};
}

sub lookup_legacy_colname {
    my $self    = shift;
    my $type    = shift;
    my %map     = (
        alert       => "alerts",
        alertgroup  => "alertgroups",
        event       => "events",
        entry       => "entries",
        incident    => "incidents",
        handler     => "incident_handler",
        guide       => "guides",
        user        => "users",
        file        => "files",
    );
    return $map{$type};
}

sub get_pct {
    my $self    = shift;
    my $remain  = shift;
    my $total   = shift;

    my $numerator   = $total - $remain;
    if ( $total > 0 ) {
        return int(($numerator/$total)*10000)/100;
    }
    return "";
}

sub get_unneeded_fields {
    my $self        = shift;
    my $collection  = shift;
    my %unneeded    = (
        alert      => [ 
            qw(_id collection data_with_flair searchtext entities scot2_id 
            triage_ranking triage_feedback triage_probs
            disposition downvotes upvotes) 
        ],
        alertgroup => [ 
            qw( _id collection closed searchtext files 
                scot2_id downvotes upvotes open promoted) 
        ],
        event      => [ qw( _id collection ) ],
        incident   => [ qw( _id collection ) ],
        entry      => [ qw( _id collection body_flaired body_plaintext) ],
        handler    => [ qw( _id parsed )],
        guide      => [ qw( _id history )],
        user       => [ qw( _id display_orientation theme tzpref 
                            flair last_activity_check) ],
        file       => [ qw( _id scot2_id fullname )],
    );
    return $unneeded{$collection};
}

sub handle_huge_entry {
    my $self    = shift;
    my $id      = shift;
    open my $out, ">>", "/tmp/huge.entries.txt";
    print $out $id."\n";
    close $out;
}


1;
