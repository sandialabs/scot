package Scot::Parser::Sourcefire;

use lib '../../../lib';
use Moose;

extends 'Scot::Parser';

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    $self->log->debug("checking for sourcefire email");

    if ( $subject =~ /auto generated email/i ) {
        $self->log->debug("it is!");
        return 1;
    }
    $self->log->debug("NOPE");
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
        source      => [ qw(email sourcefire) ],
    );

    $log->trace("Parsing Sourcefire email");

#    my $regex   = qr{\[(?<sid>.*?)\] "(?<rule>.*?)" \[Impact: (?<impact>.*?)\] +From "(?<from>.*?)" at (?<when>.*?) +\[Classification: (?<class>.*?)\] \[Priority: (?<pri>.*?)\] {(?<proto>.*)} (?<rest>.*) *};

    my $regex   = qr{
        \[(?<sid>.*?)\]
        \s
        "(?<rule>.*?)"
        \s
        \[Impact: (?<impact>.*?)\]
        \s+
        From "(?<from>.*?)"
        \s
        at
        \s
        (?<when>.*?)
        \s+
        \[Classification: (?<class>.*?)\]
        \s
        \[Priority: (?<pri>.*?)\]
        \s
        \{(?<proto>.*)\}
        \s
        (?<rest>.*)
        \s*
    };

    my $body    = $href->{body_html} // $href->{body_plain};
       $body    =~ s/[\n\r]/ /g;
       $body    =~ m/$regex/g;

    $json{data}     = {
        sid         => $+{sid},
        rule        => $+{rule},
        impact      => $+{impact},
        from        => $+{from},
        when        => $+{when},
        class       => $+{class},
        priority    => $+{pri},
        proto       => $+{proto},
    };

    my $rest    = $+{rest};

    unless ($rest) {
        my $badsrc = $href->{body_html} // $href->{body_plain};
        $log->error("PARSE ERROR on: ".$badsrc);
        return wantarray ? %json : \%json;
    }

    my ($fullsrc, $fulldst) = split(/->/, $rest);
    my ($srcip, $srcport)   = split(/:/, $fullsrc);
    my ($dstip, $dstport)   = split(/:/, $fulldst);


    $json{data}{srcip}       = $srcip;
    $json{data}{srcport}     = $srcport;
    $json{data}{dstip}       = $dstip;
    $json{data}{dstport}     = $dstport;
    $json{columns}           = [ keys %{$json{data}} ];
    return wantarray ? %json : \%json;
}

sub get_sourcename {
    return "sourcefire";
}
1;

