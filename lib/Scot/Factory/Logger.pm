package Scot::Factory::Logger;

use Data::Dumper;
use Log::Log4perl;
use Log::Log4perl::Layout;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;

use Moose;
extends qw(Scot::Factory);

sub make {
    return shift->get_logger;
}

has product => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'Log::Log4perl::Logger',
);

has logger_name => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_logger_name',
);

sub _build_logger_name {
    my $self    = shift;
    my $attr    = "logger_name";
    my $default = "SCOT";
    my $envname = "scot_util_loggerfactory_logger_name";
    return $self->get_config_value($attr,$default);
}

has layout => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_layout',
);

sub _build_layout {
    my $self    = shift;
    my $attr    = "layout";
    my $default = "%d %7p [%P] %15F{1}: %4L %m%n";
    my $envname = "scot_util_loggerfactory_layout";
    return $self->get_config_value($attr,$default);
}

has appender_name => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_appender_name',
);

sub _build_appender_name {
    my $self    = shift;
    my $attr    = "appender_name";
    my $default = "scot_log";
    my $envname = "scot_util_loggerfactory_appender_name";
    return $self->get_config_value($attr,$default);
}

has logfile => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_logfile',
);

sub _build_logfile {
    my $self    = shift;
    my $attr    = "logfile";
    my $default = "/var/log/scot/scot.log";
    my $envname = "scot_util_loggerfactory_logfile";
    return $self->get_config_value($attr,$default);
}

has log_level => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_log_level',
);

sub _build_log_level {
    my $self    = shift;
    my $attr    = "log_level";
    my $default = "DEBUG";
    my $envname = "scot_util_loggerfactory_loglevel";
    return $self->get_config_value($attr,$default);
}

sub get_log {
    # not being consistent sux`
    my $self    = shift;
    return $self->get_logger;
}

# factory object, creates a Log::Log4perl not a Scot::Util::Log
sub get_logger {
    my $self    = shift;
    my $logname = $self->logger_name;
    my $log     = Log::Log4perl->get_logger($logname);

    my $layoutname  = $self->layout;
    my $layout      = Log::Log4perl::Layout::PatternLayout->new($layoutname);

    my $appendername    = $self->appender_name;
    my $logfilename     = $self->logfile;
    my $append          = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::File',
        name        => $appendername,
        filename    => $logfilename,
        autoflush   => 1,
    );

    $append->layout($layout);
    $log->add_appender($append);

    my $levelname = $self->log_level;
    $log->level($levelname);

    $log->debug("Logger is initialized!");

    return $log;
}


1;
