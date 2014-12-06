#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Mojo::DOM;

=head1 NAME

test_ee.pl

=head1 DESCRIPTION

Perl program to 

test new entity extraction

=cut

=head1 SYNOPSIS

    $0 

=cut

use lib '../lib';
# use lib '/opt/sandia/webapps/scot3/lib';

use File::Slurp;    # to read config file
use Data::Dumper;   
use DateTime;
use DateTime::Format::Strptime;
use Log::Log4perl;
use Scot::Util::Imap;
use Scot::Bot::ForkAlerts;
use Getopt::Long qw(GetOptions);


$| = 1;

my $event_id;

GetOptions(
    'event_id=s'  => \$event_id,
) or die <<EOF

Invalid Option!

    usage:  $0 
        [--event_id xyz]                 extract from event_id

EOF
;

=head1 PROGRAM ARGUMENTS

=over 4


=back

=cut

my $env  = Scot::Env->new(
    config_file => '../scot.conf',
    mode        => 'production',
);

$env->log->debug("-----------------");
$env->log->debug(" $0 Begins");
$env->log->debug("-----------------");

my $redis   = $env->redis;
my $mongo   = $env->mongo;
my $ee      = $env->entity_extractor;

my $event   = $mongo->read_one_document({
    collection  => "events",
    match_ref   => { event_id   => $event_id },
});

my $entry_aref = $event->get_entries(['ir']);

process_entries($ee, $entry_aref);

$env->log->debug("========= Finished $0 ==========");
exit 0;

sub process_entries {
    my $ee      = shift;
    my $aref    = shift;

    unless ( defined $aref ) {
        return;
    }

    foreach my $entry (@$aref) {
        my $ehref  = $ee->process_html($entry->body);
        print "-----------------------------------\n";
        print " Entry: ".$entry->entry_id."\n";
        print $entry->body."\n";
        print "-----------------------------------\n";
        print Dumper($ehref);
        print "===================================\n";
    }
}

