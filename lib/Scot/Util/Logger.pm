package Scot::Util::Logger;

use Data::Dumper;
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
        print Dumper($config),"\n";
        warn ("Invalid Configuration for Logger!");
        $config = {
            logger_name => 'SCOT',
            layout      => '%d %7p [%P] %15F{1}: %4L %m%n',
            appender_name   => 'scot_log',
            logfile         => '/var/log/scot/scot.log',
            log_level       => 'DEBUG',
        };
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
