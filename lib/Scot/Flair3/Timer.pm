package Scot::Flair3::Timer;

use Time::HiRes qw(gettimeofday tv_interval);
use Moose;
use Moose::Exporter;
use Data::Dumper;

Moose::Exporter->setup_import_methods(
    as_is   => [ 'get_timer' ],
);

sub get_timer {
    my $title   = shift // '';
    my $log     = shift;
    my $start   = [ gettimeofday ];
    my @c       = caller(1);
    my $msg     = join(' ',
        $c[3],
        $c[2],
        $title);

    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [gettimeofday]);
        if ( defined $log and ref($log) eq "Log::Log4perl::Logger" ) {
            my $m = sprintf "%-30s => %10f seconds", $msg, $elapsed;
            $log->info($m);
        }
        return $elapsed;
    };
}


__PACKAGE__->meta->make_immutable;

1;
