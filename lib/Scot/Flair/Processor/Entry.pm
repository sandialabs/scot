package Scot::Flair::Processor::Entry;

use strict;
use warnings;
use utf8;
use lib '../../../../lib';

use Data::Dumper;
use Scot::Flair::Io;
use Scot::Flair::Imgmunger;

use Moose;
extends 'Scot::Flair::Processor';

sub flair {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->env->log;

    $log->info("=== Entry Flair Processor Begins");
    my $entry   = $self->retrieve($data);
    if ( defined $entry ) {
        my $results = $self->flair_object($entry);
    }
    else {
        $log->error("Unable to retrieve Entry from ", {filter=>\&Dumper, value=>$data});
    }
    $log->info("=== Entry Flair Processor Ends");

}

sub flair_object {
    my $self    = shift;
    my $entry   = shift;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("flair_entry");
    my $eid     = $entry->id;
    
    $log->debug("+++ flairing Entry $eid");
    
    my $body    = $self->preprocess_body($entry);
    my $tracker = "[entry: $eid]";
    my $result  = $self->process_html($body, $tracker);

    $self->update_entry($entry, $body, $result);

    my $elapsed = &$timer;
    $log->info("TIME == $elapsed secs :: flair entry $eid"); 
    $log->debug("+++ done flairing Entry ".$entry->id);

    return $result;
}

sub split_entry {
    my $self    = shift;
    my $entry   = shift;
    my $io      = $self->scotio;
    my @entries = ();

    my $body    = $entry->body;
    my $bsize   = length($body);
    my $limit   = 4 * 1024 * 1024; # 4 MB
    if ( $bsize > $limit ) {
        my @parts = $self->split_body($body, $limit);
        my $parent  = $entry->id;

        my $first_part  = shift @parts;
        $io->update_entry_body($entry, $first_part);

        foreach my $part (@parts) {
            my $child = $io->create_child_entry($entry, $part);
            push @entries, $child;
        }
    }
    else {
        # put original at the head
        unshift @entries, $entry;
    }
    return wantarray ? @entries : \@entries;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $body    = shift;
    my $results = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;

    $log->debug("[$$] updating Entry ".$entry->id);

    $io->update_entry($entry, $body, $results);

}

sub preprocess_body {
    my $self    = shift;
    my $entry   = shift;
    my $body    = $entry->body;
    my $log     = $self->env->log;

    $log->trace("preprocessing $body");

    # the body html may contain images with src's outside of scot
    # this can be a source of data leakage.  Imgmunger will download
    # external sources and create files for datauri images.
    my $newhtml = $self->munge_images($entry); 
    # write changes in body immediately to entry
    # also entries can be almost to limit of size of entry and will
    # need to be split



}

sub munge_images {
    my $self    = shift;
    my $entry   = shift;
    my $body    = $entry->body;
    my $munger = Scot::Flair::Imgmunger->new({
        env     => $self->env, 
        scotio  => $self->scotio
    });
    my $newhtml = $munger->process_body($entry->id, $body);

    return $newhtml;
}


1;
