package Scot::Parser::Forefront;

use lib '../../../lib';
use Moose;

extends 'Scot::Parser';

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    if ( $subject =~ /microsoft forefront/i ) {
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
        source      => [ qw(email forefront) ],
    );

    $log->trace("Parsing forefront email");

    my $body    = $href->{body_plain};

    my %upper   = $body =~ m/[ ]{4}(.*?):[ ]+\"(.*?)\"/gms;
    my %lower   = $body =~ m/[ ]{6}(.*?):[ ]*(.*?)$/gms;
    my @columns = ();
    my %data    = ();

    foreach my $href (\%upper, \%lower) {
        while ( my ($k, $v) = each %$href ) {
            $k  =~ s/^[ \n\r]+//gms;
            $k  =~ s/ /_/g;
            $k  =~ s/\./_/g;
            push @columns, $k;
            $data{$k} = $v;
        }
    }

    $json{data}     = [ \%data ];
    $json{columns}  = keys %data;

    return wantarray ? %json : \%json;
}

sub get_sourcename {
    return "forefront";
}
1;

