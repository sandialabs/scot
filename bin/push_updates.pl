#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Sys::RunAlone retry => 10;

=head1 NAME

push_updates.pl

=head1 DESCRIPTION

Perl program to read all updates to SCOT databases
and push them to secondary databases

=cut

=head1 SYNOPSIS

    $0  --mode [ production | development ]
        --config=filename
        --dryrun
        --keyfile=rsa_filename

=cut

use lib '../lib';

use File::Slurp;    # to read config file
use Data::Dumper;   
use Log::Log4perl;
use Scot::Env;
use Scot::Bot::Pusher;
use Scot::Util::Mongo;
use Getopt::Long qw(GetOptions);

my $mode        = 'production';
my $config_file = "../scot.conf";
my $dryrun      = 0;
my $rsa_file    = "FULLPATH_TO_SSH_PRIVATE_KEY";

GetOptions(
    "mode=s"    => \$mode,  # development or production
    "config=s"  => \$config_file,
    "dryrun"    => \$dryrun,
    "keyfile=s" => \$rsa_file,
) or die <<EOF

Invalid Option!

    usage:  $0 
        --mode quality          section of scot.conf to use for connection info
        --config filename       use this file as config info
        --dryrun                do not actually do updates on remote systems
        --keyfile filename      specify the ssh keyfile to use
EOF
;


if ( $dryrun ) {
    print "DRY RUN. NO actual changes will be made.\n";
}

my $env  = Scot::Env->new(
    config_file => $config_file,
    mode        => $mode,
);

$env->log->debug("-----------------");
$env->log->debug(" $0 Begins");
$env->log->debug("-----------------");
$env->log->debug("config: ".Dumper($env->config));


my @push_hosts  = qw(
    HOST_TO_PUSH_CHANGES_TO
);


my $bot = Scot::Bot::Pusher->new({
    env         => $env,
    push_hosts  => \@push_hosts,
    rsa_file    => $rsa_file,
    dryrun      => $dryrun,
});

$bot->run();


$env->log->debug("========= Finished $0 ==========");
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

=item L<Scot::Env>

=item L<Scot::Bot>

=item L<Scot::Model::Alertgroup>

=item L<Scot::Model::Alert>

=item L<Scot::Bot::Alerts>

=item L<Scot::Bot::Parser>

=back


