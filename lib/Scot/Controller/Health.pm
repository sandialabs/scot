package Scot::Controller::Health;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Util::Mongo;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);

use base 'Mojolicious::Controller';

sub check {
    my $self    = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;

    my $cursor = $mongo->read_documents({
       collection => "checkpoints",
       match_ref  => {'type' => 'health_check'}
    });
    my $status = {};
    my $error_occurred = 0;
    while (my $service = $cursor->next_raw) {
       eval{
          my $periodicity = $service->{periodicity};
          my $last_run    = $service->{last_checkin};
          my $service_name = $service->{name};
          my $current     = time();
          if(($current - $periodicity) > $last_run) {
             $status->{$service_name} = 'DOWN';
             $error_occurred = 1;
          } else {
             $status->{$service_name} = 'up';
          }
       };
    }
    my $href = {};
    $href->{'services'} = $status;
    if($error_occurred == 0) {
      $href->{'overall'} = 'All Services up';
    } else {
      $href->{'overall'} = 'At least one service DOWN';
    }
    $self->render(
        json    => {
            title   => "Last Run",
            action  => 'GET',
            thing   => 'multiple',
            status  => 'ok',
            data    => $href,
        }
    );
}
1;




