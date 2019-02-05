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
    my $self    = shift;
    my $config  = shift;
    return $self->get_logger($config);
}

has product => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'Log::Log4perl::Logger',
);

# factory object, creates a Log::Log4perl not a Scot::Util::Log
sub get_logger {
    my $self    = shift;
    my $config  = shift;
    my $logname      = $self->get_config_value( "logger_name",   $config );
    my $layoutname   = $self->get_config_value( "layout",        $config );
    my $appendername = $self->get_config_value( "appender_name", $config );
    my $logfilename  = $self->get_config_value( "logfile",       $config );
    my $levelname    = $self->get_config_value( "log_level",     $config );

    my $log    = Log::Log4perl->get_logger($logname);
    my $layout = Log::Log4perl::Layout::PatternLayout->new($layoutname);
    my $append = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::File',
        name      => $appendername,
        filename  => $logfilename,
        autoflush => 1,
    );

    $append->layout($layout);
    $log->add_appender($append);
    $log->level($levelname);

    $log->debug("Logger is initialized!");

    return $log;
}


1;
