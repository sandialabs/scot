package Scot::Bot::Parser::Sourcefire;

use lib '../../../../lib';
use strict;
use warnings;
use v5.10;

use Mail::IMAPClient;
use Mail::IMAPClient::BodyStructure;
use MIME::Base64;
use MongoDB;
use Scot::Model::Alert;
use Scot::Util::Mongo;
use Data::Dumper;
use Readonly;

use Moose;
extends 'Scot::Bot::Parser';

Readonly my $ALERTREGEX   => qr|^\[(?<sid>.*?)\] "(?<rule>.*?)" \[Impact: (?<impact>.*?)\] +From "(?<from>.*?)" at (?<when>.*?) +\[Classification: (?<class>.*?)\] \[Priority: (?<pri>.*?)\] {(?<proto>.*)} (?<rest>.*) *$|;



sub parse_body {
    my $self    = shift;
    my $bhref   = shift;
    my $body    = $bhref->{html} // $bhref->{plain};
    my $log     = $self->env->log;

    $log->debug("parsing body");

    $body   =~ s/[\n\r]/ /g;
    
    $log->debug("PARSING BODY of ".Dumper($body));

    $body =~ m/$ALERTREGEX/g;

    $log->debug("Extracted " . Dumper($+));

    my $rest    = $+{rest};
    my ($fullsrc, $fulldst)     = split(/->/, $rest);
    my ($srcip, $srcport)       = split(/:/, $fullsrc);
    my ($dstip, $dstport)       = split(/:/, $fulldst);
    
    my $data    = {
        sid             => $+{sid},
        rule            => $+{rule},
        impact          => $+{imapct},
        from            => $+{from},
        when            => $+{when},
        class           => $+{class},
        priority        => $+{pri},
        proto           => $+{proto},
        srcip           => $srcip,
        srcport         => $srcport,
        dstip           => $dstip,
        dstport         => $dstport,
    };

    return [$data], [qw(sid rule impact from when class priority proto srcip srcport dstip dstport)];
}


__PACKAGE__->meta->make_immutable;
1;
