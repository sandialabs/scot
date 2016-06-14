package Scot::Util::Logger;

use Log::Log4perl;
use Log::Log4perl::Layout;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;

sub new {
    my $class   = shift;
    my $config  = shift;     # href of config items

    unless (
        defined($config->{logger_name}) &&
        defined($config->{layout}) &&
        defined($config->{appender_name}) &&
        defined($config->{logfile}) &&
        defined($config->{log_level}) ) {

        die ("Invalid Configuration for Logger!");
    }

    my $log     = Log::Log4perl->get_logger($config->{logger_name});
    my $layout  = Log::Log4perl::Layout::PatternLayout->new($config->{layout});
    my $append  = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::File',
        name        => $config->{appender_name},
        filename    => $config->{logfile},
        autoflush   => 1,
    );
    $append->layout($layout);
    $log->add_appender($append);
    $log->level(${$config->{log_level}});
    return $log;
}

1;
