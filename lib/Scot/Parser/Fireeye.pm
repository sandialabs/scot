package Scot::Parser::Fireeye;

use lib '../../../lib';
use Moose;

extends 'Scot::Parser';

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    if ( $from =~ /fireeye/i ) {
        return 1;
    }
    return undef;
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
        data        => [],
        source      => [ qw(email splunk) ],
    );

    $log->trace("Parsing Fireeye email");

    my $body    = $href->{body_plain};
       $body    =~ s/\012\015?|\015\012?//g;

    my $fejson  = JSON->new->relaxed(1);
    my $decoded;

    try {
        $decoded = $fejson->decode($body);
    }
    catch {
        $log->error("Invalid JSON in FireEye message!");
        $log->error("body = ",{filter=>\&Dumper, value =>$body});
        return undef;
    };

    my $data    = {
        fireeye_alert   => Dumper($decoded),
    };

    $json{data}     = [ $data ];
    $json{columns}  = keys %$data;

    return wantarray ? %json : \%json;
}

sub get_sourcename {
    return "fireeye";
}

1;

