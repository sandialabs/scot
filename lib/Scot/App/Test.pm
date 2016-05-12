package Scot::App::Test;
use lib '../../lib';
use Scot::App;
use Data::Dumper;
use Moose;

extends 'Scot::App';

sub do_it {
    my $self    = shift;
    my $conf    = $self->config;

    print Dumper($conf);
}
1;
