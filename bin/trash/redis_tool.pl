#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use lib '../lib';
use Mojo::DOM;
use Scot::Env;

=head1 NAME

redis_tool.pl

=head1 DESCRIPTION

Perl program to rebuild the redis database 
    from the html in entries
    or alerts
    or to reindex search


=cut

=head1 SYNOPSIS

    $0 
        [-v]               verbose
        [-epoch_start=i]   only get entries after epoch
        [-epoch_stop=i]    only get entries before epoch
        [-dry_run]         don't actually do anything
        [-mode=s]          the mongo database to query
        [-config=s]        the config file
        [-notes]           only update the notes
        [-search-alerts]   only search alerts
        [-search-entries]  only search entries
        [-entries]         only update the entity to entries and 
                                    entry to entities databases
        [-alerts]          only update the entity to alers and 
                                    alert to entities databases
        [-sniplength=i]    the length of the snippet (default 4)
        [-h]               help!

=cut


use File::Slurp;    # to read config file
use Data::Dumper;   
use Log::Log4perl;
use Scot::Util::Imap;
use Scot::Bot::ForkAlerts;
use Getopt::Long qw(GetOptions);

my $verbose         = 0;
my $mode            = 'production';
my $start           = 0;
my $stop            = time();
my $dry_run         = 0;
my $notes           = 0;
my $search_alerts   = 0;
my $search_entries  = 0;
my $index_entries   = 0;
my $index_alerts    = 0;
my $len             = 4;
my $config          = "../scot.conf";

GetOptions(
    "verbose"       => \$verbose,
    "mode=s"        => \$mode,
    "epoch_start=i" => \$start,
    "epoch_stop=i"  => \$stop,
    "config=s"      => \$config,
    "sniplength=i"  => \$len,
    "dry_run"       => \$dry_run,
    "notes"         => \$notes,
    "search-alerts" => \$search_alerts,
    "search-entries"=> \$search_entries,
    "entries"       => \$index_entries,
    "alerts"        => \$index_alerts,
) or die <<EOF

Invalid Option!

    usage:  $0 
        [-v]               verbose
        [-epoch_start=i]   only get entries after epoch
        [-epoch_stop=i]    only get entries before epoch
        [-dry_run]         don't actually do anything
        [-mode=s]          the mongo database to query
        [-config=s]        the config file
        [-notes]           only update the notes
        [-search-alerts]   only search alerts
        [-search-entries]  only search entries
        [-entries]         only update the entity to entries and 
                                    entry to entities databases
        [-alerts]          only update the entity to alers and 
                                    alert to entities databases
        [-sniplength=i]    the length of the snippet (default 4)
        [-h]               help!

EOF
;

=head1 PROGRAM ARGUMENTS

=over 4


=back

=cut

my $env  = Scot::Env->new(
    config_file => $config,
    mode        => $mode,
);

$env->log->debug("-----------------");
$env->log->debug(" $0 Begins");
$env->log->debug("-----------------");

my $redis   = $env->redis;
my $mongo   = $env->mongo;

# this structure allows you to run multiple copies of this tool
# each working on a different part of the indexing puzzle
# e.g. ./redis_tool.pl -notes&;./redis_tool.pl -alerts&


if ($notes) {
    index_notes();
}
elsif ($search_entries) {
    index_for_search("entries", "entry_id", "body_plaintext");
}
elsif ($search_alerts) {
    index_for_search("alerts", "alert_id", "searchtext");
}
elsif ($index_entries) {
    index_entries();
}
elsif ($index_alerts) {
    index_alerts();
}
else {
     die "  usage:  $0 \
        [-v]               verbose\
        [-epoch_start=i]   only get entries after epoch\
        [-epoch_stop=i]    only get entries before epoch\
        [-dry_run]         don't actually do anything\
        [-mode=s]          the mongo database to query\
        [-config=s]        the config file\
        [-notes]           only update the notes\
        [-search-alerts]   only search alerts\
        [-search-entries]  only search entries\
        [-entries]         only update the entity to entries and \
                                    entry to entities databases\
        [-alerts]          only update the entity to alers and \
                                    alert to entities databases\
        [-sniplength=i]    the length of the snippet (default 4)\
        [-h]               help!";

}

$env->log->debug("========= Finished $0 ==========");
exit 0;

sub get_entities {
    my $html    = shift;
    my $dom     = Mojo::DOM->new;
    $dom->parse($html);
    my $ehref   = {};

    my $entity_elements = $dom->find('[class*="entity"]');

    foreach my $dom_element ($entity_elements->each) {
        my $value   = $dom_element->attr->{'data-entity-value'};
        my $type    = $dom_element->attr->{'data-entity-type'};

        if ( defined $value and defined $type ) {
            $ehref->{$value} = $type;
            if ( $type eq "domain" ) {
                my @parts   = reverse( split(/\./, $value) );
                my $dpart   = shift @parts;
                foreach my $part (@parts) {
                    $dpart = $part . '.' . $dpart;
                    $ehref->{$dpart}    = $type;
                }
            }
        }
        else {
            say "WARN: no value or type on entity! ".Dumper($dom_element);
        }
    }
    return $ehref;
}
    
sub index_for_search {
    my $collection  = shift;
    my $idfield     = shift;
    my $textfield   = shift;
    
    my $processed   = 0;
    my $cursor      = $mongo->read_documents({
        collection  => $collection,
        match_ref   => {
            '$or'   => [
                { created => { '$gte'   => $start } },
                { updated => { '$gte'   => $start } },
            ],
        },
        sort_ref    => { $idfield => 1 },
    });
    $cursor->immortal(1);
    my $count   = $cursor->count;
    say "will index for search $count entries";

    DB::enable_profile('nytprof.out');
    while ( my $object  = $cursor->next ) {
        my $id          = $object->$idfield;
        my $text        = $object->$textfield;
        next if ($text eq '');

        unless ($dry_run) {
            $redis->add_text_to_search({
                text        => $text,
                id          => $id,
                collection  => $collection,
                sniplength  => $len,
            });
        }
        $processed++;
         printf "%d of %d (%2.2f)\n",
                 $processed, $count,
                 (($processed * 100)/$count);
        if ($processed >= 20) {
            DB::finish_profile();
            say "profiling stopped";
        }
        
    }
    print "Search Index ($collection) done\n";
}

sub index_notes {
    my $cursor  = $mongo->read_documents({
        collection  => "entities",
        match_ref   => {
            '$and'  => [
                { notes => { '$not' => { '$size' => 0 } } },
                { notes => { '$exists' => 1 } },
            ],
        },
    });
    my $total   = $cursor->count;
    say "Will convert $total notes";

    while ( my $entity = $cursor->next ) {
        my $notes   = $entity->notes;
        my $value   = $entity->value;

        if ( defined $notes ) {
            foreach my $n (@$notes) {
                my $text    = $n->{text};
                my $who     = $n->{who};

                if ( $verbose ) {
                    say "... Setting $value note";
                }
                unless ($dry_run) {
                    $redis->set_entity_note($value, $who, $text);
                }
            }
        }
    }
}
sub index_entries {
    my $cursor  = $mongo->read_documents({
        collection  => "entries",
        match_ref   => {
            '$or'   => [
                { created => { '$gte'   => $start } },
                { updated => { '$gte'   => $start } },
            ],
        },
        sort_ref    => { entry_id => 1 },
    });
    $cursor->immortal(1);

    my $total   = $cursor->count;
    say "will conver $total entries";
    my $processed   = 0;

    while ( my $entry = $cursor->next ) {
        my $id      = $entry->entry_id;
        my $type    = $entry->target_type;
        my $tid     = $entry->target_id;

        # types are singular and we need a plural
       # if ( substr $type, -1 eq "y" ) {
       #     my $junk = substr $type, -1, 1, 'ie';
       # }
       # my $plural  = lc($type) . "s";

        unless ($dry_run) {

        }

        if(defined($entry->{body_flaired})) {       
            my $entities    = get_entities($entry->body_flaired);
    
            # [ { entity_value    => type }, ... ]
    
            foreach my $key (keys %$entities) {
                if ($verbose) {
                    say "... Key $key";
                }
                unless ($dry_run) {
                    $redis->add_entrys_entities({
                        target_type     => $type,
                        target_id       => $tid,
                        entry_id        => $id,
                        entity_value    => $key,
                        entity_type     => $entities->{$key},
                    });
                }
            }
        }
        $processed++;
        printf "Entries processed %d (%2.2f pct.)\n",
                $processed,
                (($processed * 100)/$total);
    }
}
sub index_alerts {

    my $cursor = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => {
            '$or'   => [
                { created => { '$gte'   => $start } },
                { updated => { '$gte'   => $start } },
            ],
        },
        sort_ref    => { when => 1 },
    });
    $cursor->immortal(1);
    my $total   = $cursor->count();
    say "will conver $total alerts";
    my $processed = 0;

    while ( my $alert   = $cursor->next ) {
        my $id      = $alert->alert_id;
        my $agid    = $alert->alertgroup;
        my $data    = $alert->data_with_flair;
        my $html    = '';
        foreach my $key (keys %{$data} ) {
            if ( defined $key and defined $data->{$key} and $data->{$key} ne '' ) {
                $html .= ' '. $data->{$key};
            }
        }
        my $entities = get_entities($html);

        foreach my $key ( keys %$entities ) {
            if ($verbose) {
                say "... Key $key";
            }
            unless ($dry_run) {
                $redis->add_entrys_entities({
                    target_type     => "alert",
                    target_id       => $id,
                    entry_id        => $id,
                    entity_value    => $key,
                    entity_type     => $entities->{$key},
                });
                $redis->add_entrys_entities({
                    target_type     => "alertgroup",
                    target_id       => $agid,
                    entry_id        => $agid,
                    entity_value    => $key,
                    entity_type     => $entities->{$key},
                });
            }
        }
        $processed++;
        printf "Alerts processed %d (%2.2f pct.)\n",
                $processed,
                (($processed * 100)/$total);
    }
}
__END__

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Tasker>

=item L<Scot::Bot>

=item L<Scot::Model::Alertgroup>

=item L<Scot::Model::Alert>

=item L<Scot::Bot::Alerts>

=item L<Scot::Bot::Parser>

=back


