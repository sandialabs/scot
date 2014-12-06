#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Sys::RunAlone retry => 10;

=head1 NAME

alertbot.pl

=head1 DESCRIPTION

Perl program to process alert email messages and create Alertgroups/alerts from them.

=cut

=head1 SYNOPSIS

    $0 [--int] [--mode mode] [--acount username]
    [--msgid idstr] [--from addr] [--source srcname] [--ago int_minutes] 
    [--config filename] [--markread] [--mailbox mboxname] [--reprocess]

=cut

use lib '../lib';

use File::Slurp;    # to read config file
use Data::Dumper;   
use Log::Log4perl;
use Scot::Env;
use Scot::Util::Imap;
use Scot::Bot::ForkAlerts;
use Getopt::Long qw(GetOptions);

my $interactive = '';
my $mode        = 'production';
my $account     = 'EMAIL_ACCOUNT_USERNAME_HERE';
my $msgid       = '';
my $fromfilter  = '';
my $sourcefilter= '';
my $minutesago  = 120;
my $config_file = "../scot.conf";
my $markasread;
my $mailbox     = 'INBOX';
my $reprocess;

GetOptions(
    "int"       => \$interactive,
    "mode=s"    => \$mode,  # development or production
    "account=s" => \$account,
    "msgid=s"   => \$msgid,
    "from=s"    => \$fromfilter,
    "source=s"  => \$sourcefilter,
    "ago=s"     => \$minutesago,
    "config=s"  => \$config_file,
    "markread"  => \$markasread,
    "mailbox"   => \$mailbox,
    "reprocess" => \$reprocess,
) or die <<EOF

Invalid Option!

    usage:  $0 
                --int                   interactive mode
                --mode quality          section of scot.conf to use for connection info
                --account username      the entity account for the mailbox to scan
                --msgid header-msg-id   retrieve specified msg-id and parse
                --from emailaddr        retrieve messages from specified emailaddr
                --source sourcename     retrieve messages from sourcename
                --ago int_minutes       get all messages from past int_minutes ago
                --config filename       use this file as config info
                --markread              mark messages as read upon processing
                --mailbox mboxname      default is INBOX, this allows you to change that
                --reprocess             create an alert event if email msg id has been 
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

=item --account username

Allows you to specify an alternative user name to the entity account that receives the alert
emails.  .  

=item --msgid id

Allows you to select only the message in the inbox that matches the header Message-Id value.

=item --from address

Allows you to process only messages in the inbox from a given addresss. [ NOT IMPLEMENTED YET ]

=item --source sourcename

Allows you to process only messages in the inbox from a give source. [ NOT IMPLEMENTED YET ]

=item --ago int_minutes

Allows you to override the default of 120 minutes ago.  This parameter tells the bot how far back
to grab messages. 

=item --config filename

override the default config file of scot.json.  Useful for testing.

=item --markread

By default, the bot does not alter the seen status of a message in the inbox.  If you select this,
the message will be marked read.

=item --mailbox mboxname.

Override the default mailbox of INBOX for a given account.

=item --reprocess

Process the mail message even if it is already in the database.  Damn the torpedoes!  Useful for testing.

=back

=cut

my $env  = Scot::Env->new(
    config_file => $config_file,
    mode        => $mode,
    interactive => $interactive,
);

$env->log->debug("-----------------");
$env->log->debug(" $0 Begins");
$env->log->debug("-----------------");
$env->log->debug("config: ".Dumper($env->config));


my $bot = Scot::Bot::ForkAlerts->new({
    env     => $env,
});

my $opts_href   = {
    msgid           => $msgid,
};
if ( defined $fromfilter or defined $sourcefilter ) {
    $opts_href->{search}    = {
            from            => $fromfilter,
            source          => $sourcefilter,
    };
}
if ( defined $markasread and $markasread ne '') {
    $opts_href->{mark_as_read}  = $markasread;
}
if ( defined $mailbox and $mailbox ne '') {
    $opts_href->{mail_box}  = $markasread;
}
if ( defined $reprocess and $reprocess ne '') {
    $opts_href->{reprocess}  = $reprocess;
}

$bot->run($opts_href);

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


