#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

=head1 NAME

plugins.pl

=head1 DESCRIPTION

Perl program to process SCOT plugins

=cut

=head1 SYNOPSIS

    $0 [--int] [--mode mode] [--acount username]
    [--msgid idstr] [--from addr] [--source srcname] [--ago int_minutes] 
    [--config filename] [--markread] [--mailbox mboxname] [--reprocess]

=cut

use lib '../lib';

use File::Slurp;    # to read config file
use Proc::PID::File;
use Data::Dumper;   
use Log::Log4perl;
use Scot::Bot::Plugins;
use Getopt::Long qw(GetOptions);

my $interactive = '';
my $mode        = 'production';
my $config_file = "../scot.conf";

die "Already running!" if Proc::PID::File->running();

GetOptions(
    "int"       => \$interactive,
    "mode=s"    => \$mode,
    "config=s"  => \$config_file,
) or die <<EOF

Invalid Option!

    usage:  $0 
                --int                   interactive mode
                --mode quality          section of scot.json to use for connection info
                --config filename       use this file as config info
                                            processed before
EOF
;

=head1 PROGRAM ARGUMENTS

=over 4

=item --int

Interactive mode.  This option will print interactive information to the terminal.  You will also
be asked to proceed after each email is processed.  Entering 0 at prompt will turn off the prompting,
but the output to the terminal will continue.

=item --mode mode_string

This parameter selects the stanza of the scot.json to use for connection to databases, etc.  Useful
for specifying the use of the testing environment.

=item --config filename

override the default config file of scot.json.  Useful for testing.

=back

=cut

my $tasker  = Scot::Env->new(
    config_file => $config_file,
    mode        => $mode,
    interactive => $interactive,
);

$tasker->log->debug("-----------------");
$tasker->log->debug(" $0 Begins");
$tasker->log->debug("-----------------");


my $bot = Scot::Bot::Plugins->new({
    env   => $tasker,
});

$bot->run();

$tasker->log->debug("========= Finished $0 ==========");

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

