package Scot::App::Daily;

use lib '../../../lib';
use lib '/opt/scot/lib';
use strict;
use warnings;
use v5.18;

use Data::Dumper;
use DateTime;
use DateTime::Duration;
use Try::Tiny;
use Scot::Env;
use Scot::Util::Date;
use Log::Log4perl::Level;
use Statistics::Descriptive;
use Data::Dumper;
use MongoDB::Code;
use Moose;
extends 'Scot::App';

sub daily_briefing {
    my $self    = shift;
    # pull data
    my $data    = $self->get_data;
    # gnerate html email
    my $html    = $self->format_email($data);
    # send it
    $self->send_email($html);

}

sub get_data {
    my $self    = shift;
    my %results = (
        alert       => $self->get_alert_data,
        event       => $self->get_event_data,
        incident    => $self->get_incident_data,
    );

    return wantarray ? %results : \%results;
}

sub get_alert_data {
    my $self    = shift;
    
     # number of alerts open, closed, promoted
     # response time metric
}

sub get_event_data {
    my $self    = shift;

    # events created with summary 
    # number of events worked upon ( future )
    # number of events closed ( future )
}

sub get_incident_data {
    my $self    = shift;
    
    # incidents created
    # with event/summary 

}

1;
