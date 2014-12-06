#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

=head1 NAME

update_perms.pl

=head1 DESCRIPTION


=cut

=head1 SYNOPSIS


=cut

use lib '../lib';
# use lib '/opt/sandia/webapps/scot3/lib';

use File::Slurp;    # to read config file
use Data::Dumper;   
use Log::Log4perl;
use Scot::Util::Imap;
use Scot::Util::DateTimeUtils;
use Scot::Bot::Alerts;
use Getopt::Long qw(GetOptions);
use Scot::Env;

my $dutils      = Scot::Util::DateTimeUtils->new();
my $interactive = '';
my $mode        = 'quality';
my $config_file = "../scot.json";


GetOptions(
    "int"       => \$interactive,
    "mode=s"    => \$mode,
) or die <<EOF

Invalid Option!

    usage:  $0 
        --mode quality          section of scot.json to use for connection info
EOF
;

=head1 PROGRAM ARGUMENTS

=over 4

=cut 

my $tasker  = Scot::Env->new(
    config_file => $config_file,
    mode        => $mode,
);

$tasker->log->debug("-----------------");
$tasker->log->debug(" $0 Begins");
$tasker->log->debug("-----------------");

if ($tasker->already_running()) {
    $tasker->log->error("Instance of $0 already active...exiting");
    exit 2;
}


my $alert_match_ref = {
    collection  => "alerts",
    match_ref   => { 
        subject => qr/\s\s/,
        created => {
            '$gte'  => $start_epoch,
            '$lte'  => $end_epoch,
        },
   },
};

my $incident_match_ref  = {
    collection  => "incidents",
    match_ref   => { created    => { '$gte' => $start_epoch },
                     created    => { '$lte' => $end_epoch },
                   },
};

open (OUT, ">$outfile") || die "Can not open $outfile for writing.\n";

my $alert_cursor    = $mongo->read_documents($alert_match_ref);


while ( my $alert = $alert_cursor->next ) {
    say "viewing alert ".$alert->alert_id;
    my $earliest_view = get_earliest($alert->viewed_by) // -1;
    my $line    = sprintf(
        "%d, %d, %s, %d, %d\n", 
        $alert->alert_id,
        $alert->alertgroup,
        $alert->subject,
        $alert->created,
        $earliest_view
    );
    print OUT "$line";
}



$tasker->log->debug("========= Finished $0 ==========");

exit 0;

sub get_earliest {
    my $href    = shift;
#    say "href = ".Dumper($href);
    # the grep keeps NaN from blowing up the sort.
    my @times   =   sort { $a <=> $b } 
                    grep { $_ ==  $_ } 
                    map  { $href->{$_}->{when} } 
                    keys %$href;
#    say "times = ".Dumper(\@times);
    foreach my $t (@times) {
        return $t if ($t != 0);
    }
    return -1;
}


=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Env>

=item L<Scot::Bot>

=item L<Scot::Model::Alertgroup>

=item L<Scot::Model::Alert>

=item L<Scot::Bot::Alerts>

=item L<Scot::Bot::Parser>

=back

