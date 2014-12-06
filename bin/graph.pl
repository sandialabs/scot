#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Mojo::DOM;

=head1 NAME

reports.pl

=head1 DESCRIPTION

Perl program to 

do reports

=cut

=head1 SYNOPSIS

    $0 

=cut

use lib '../lib';

use File::Slurp;    # to read config file
use Data::Dumper;   
use DateTime;
use DateTime::Format::Strptime;
use Log::Log4perl;
use Scot::Util::Imap;
use Scot::Bot::ForkAlerts;
use Getopt::Long qw(GetOptions);
use JSON;

my $now = DateTime->now;
my $lastday = DateTime->last_day_of_month(year=> $now->year, month=>$now->month);

$| = 1;

my $output  = "/tmp/graph.json";

GetOptions(
    'output=s'  => \$output,
) or die <<EOF

Invalid Option!

    usage:  $0 
        [--ouptut filename]                 where to write the json output

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



print "SCOT Entity Event Graph\n\n";

my %data;

my $event_cursor    = $mongo->read_documents({
    collection  => "events",
    match_ref   => {},
});

my $entity_count    = 0;
my $edge_count      = 0;
my %entity_db;

while ( my $event = $event_cursor->next ) {
    printf "Event: %d\n", $event->event_id;

    push @{$data{nodes}}, {
        id      => "ev".$event->event_id,
        label   => "SCOT-".$event->event_id,
	color	=> '#ff6600',
    };
    my @entities    = $redis->get_objects_entity_values($event);
    printf "    %4d Entities associated\n", scalar(@entities);

    foreach my $entity (@entities) {
	unless ( $entity_db{$entity} ) {
		my $href	= {
		    id      => "n".$entity_count,
		    label   => $entity,
		};
		push @{$data{nodes}}, $href;
		$entity_db{$entity} = $href;
        	$entity_count++;
	}
        push @{$data{edges}}, {
            id      => "e".$edge_count,
            source  => "ev".$event->event_id,
            target  => $entity_db{$entity}{id},
        };
        $edge_count++;
    }
}
my $json    = JSON->new;
$json->indent(1);
my $jtext   = $json->encode(\%data);

write_file($output, $jtext);


    




$env->log->debug("========= Finished $0 ==========");
exit 0;

