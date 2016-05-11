package Scot::Parser::Generic;

use lib '../../../lib';
use Moose;

extends 'Scot::Parser';

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    return 1;
}

sub parse_message {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my %json    = (
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [{
            alert   => $href->{body_plain},
            columns => [qw(alert)],
        }],
        source      => [ qw(email generic) ],
    );

    $log->trace("Parsing generic email");

    return wantarray ? %json : \%json;
}

sub get_sourcename {
    return "generic";
}
1;

