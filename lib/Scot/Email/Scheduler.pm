package Scot::Email::Scheduler;

use strict;
use warnings;


=head1 Scot::Email::Scheduler

this module will run as process or as a container and fork off copies
to process various inboxes as defined in config file.

=cut

use lib '../../../lib';
use Data::Dumper;
use Scot::Env;
use Parallel::ForkManager;
use Module::Runtime qw(require_module);
use Moose;
extends 'Scot::App';

has sleep_interval => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 30,
);

has max_processes => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_max_processes',
);

sub _build_max_processes {
    my $self    = shift;
    my $attr    = "max_processes";
    my $default = 0;
    my $envname = "scot_app_mail_max_processes";
    return $self->get_config_value($attr, $default, $envname);
}

has interactive => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_interactive',
);

sub _build_interactive {
    my $self    = shift;
    my $attr    = "interactive";
    my $default = "no";
    my $envname = "scot_app_mail_interactive";
    return $self->get_config_value($attr, $default, $envname);
}

has verbose => (
    is      => 'rw',
    isa     => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_verbose',
);

sub _build_verbose {
    my $self    = shift;
    my $attr    = "verbose";
    my $default = 0;
    my $envname = "scot_app_mail_verbose";
    return $self->get_config_value($attr, $default, $envname);
}

has mailboxes => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_mailboxes',
);

sub _build_mailboxes {
    my $self    = shift;
    my $attr    = "mailboxes",
    my $default = [
        # {
        #   description => "alert_inbox",
        #   mailserver  => "mail.domain.com",
        #   port        => 993,
        #   username    => "mailbox_username",
        #   password    => "password_for_user",
        #   inbox       => "INBOX", # usually
        #   ssl_opts    => [ 
        #       SSL_verify_mode, 1
        #   ],
        #  queue => "/queue/queue_name_that_will_process_message",
        # },
    ];
    my $envname = "scot_app_mail_mailboxes";
    return $self->get_config_value($attr, $default, $envname);
}

has dry_run => (
    is      => 'ro',
    isa     => 'Bool',
    required=> 1,
    default => 0,
);

has mode    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'continuous',
);

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my @mailboxes   = @{$self->mailboxes};
    my $pm  = Parallel::ForkManager->new($self->max_processes);

    my $mode    = $self->env->mode;

    if ( $mode eq "cron" ) {
        $self->single($pm, \@mailboxes);
    }
    else {
        $self->continuous($pm, \@mailboxes);
    }
}

sub single {
    my $self        = shift;
    my $pm          = shift;
    my $mailboxes   = shift;
    my $log         = $self->log;

    $self->process_mailboxes($pm, $mailboxes);

}

sub continuous {
    my $self    = shift;
    my $pm      = shift;
    my $mailboxes = shift;
    my $log     = $self->log;
    my %lastrun = ();

    while (1) {
        $self->process_mailboxes($pm, $mailboxes, \%lastrun);
        sleep($self->sleep_interval);
    }
}

sub process_mailboxes {
    my $self        = shift;
    my $pm          = shift;
    my $mailboxes   = shift;
    my $lastrun     = shift;
    my $log         = $self->env->log;

    $log->debug("-"x60);
    MBOX:
    foreach my $mbox (@{$mailboxes}) {

        my $boxname = $mbox->{name};
        my $last    = $lastrun->{$boxname};
        if ( $self->time_to_run($mbox, $last) ) {
            $lastrun->{$boxname} = time();
            $self->fork_processor($pm, $mbox);
        }
        $log->debug("moving to next mailbox");
    }
    $log->debug("~"x60);
    $pm->wait_all_children;
}
    

sub time_to_run {
    my $self    = shift;
    my $mbox    = shift;
    my $last    = shift;
    my $log     = $self->env->log;
    my $name    = $mbox->{name};

    if ( ! $mbox->{active} ) {
        $log->debug("$name is not active.");
        return undef;
    }

    my $interval    = $mbox->{check_interval};

    $last = 0 if (! defined $last);

    my $next = $last + $interval;
    my $now  = time();

    if ( $now < $next ) {
        my $etr = $next - $now;
        $log->debug("$name will run in $etr seconds");
        return undef;
    }
    return 1;
}


sub fork_processor {
    my $self    = shift;
    my $pm      = shift;
    my $mbox    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("before fork");
    $log->trace("mbox is ",{filter=>\&Dumper, value => $mbox});

    my $pid = $pm->start and return;

    $log->debug("[$$] Worker Processing $mbox->{name} inbox");

    my $processor_class = $mbox->{processor};
    require_module($processor_class);
    my $processor = $processor_class->new({
        env     => $env,
        mbox    => $mbox,
        dry_run => $self->dry_run,
    });
    $processor->run();
    $pm->finish;
}

1;
