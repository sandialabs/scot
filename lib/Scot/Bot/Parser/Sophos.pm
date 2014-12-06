package Scot::Bot::Parser::Sophos;


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

Readonly my $ENV_FROM_ADDR  => qr{Envelope From Address: (?<efa>.*)$}m;
Readonly my $HDR_FROM_ADDR  => qr{Header From Address: (?<hfa>.*)$}m;
Readonly my $RECIPIENTS     => qr{Recipients of the message: (?<rotm>.*)$}m;
Readonly my $GMT_TIME       => qr{GMT Time/Date: (?<gtd>.*)$}m;
Readonly my $SUBJECT        => qr{Subject of the message: (?<sotm>.*)$}m;
Readonly my $SIZE           => qr{Message Size: (?<ms>.*)$}m;
Readonly my $DETAILS        => qr{Details: (?<d>.*)$}m;
Readonly my $ATTACHMENTS    => qr{Attachments\(s\): (?<a>.*)$}m;

sub get_body {
    my $self    = shift;
    my $msghash = $self->message_hash;
    my $msgid   = $msghash->{imapid};
    my $imap    = $self->imap;
    my $log     = $self->env->log;

    $log->debug("getting body");

    my $bodystruct  = $imap->get_bodystructure($msgid);

    # $log->debug("bodystruct\n".Dumper($bodystruct));

    my $bodytype    = $bodystruct->bodytype;
    my $bodysubtype = $bodystruct->bodysubtype;
    my $mime        = $bodytype . "/" . $bodysubtype;
    my @parts       = $bodystruct->parts;
    my $foodebug    = join("\n\t", @parts);
    $log->debug("Msg $msgid: (Content-type: $mime) contains $foodebug");

    foreach my $part (@parts) {
        $log->debug("Part is $part");
        next if ($part =~ /HEAD/);
        next if ($part =~ /TEXT/);

        my $body        = ""; 
        my $bodypart    = $imap->bodypart_string($msgid, $part);
        my $index       = $part - 1;
        my $substruct   = $bodystruct->{bodystructure}->[$index];

        if ($substruct) {
            my $encoding    = $substruct->{bodyenc};
            my $parttype    = $substruct->{bodytype};

            if ( $encoding ne "NIL" ) {
                $body   = Email::MIME::Encodings::decode($encoding => $bodypart);
            }
            else {
                $body   = $bodypart;
            }
        }
        else {
            $body   = $bodypart;
        }
        if ($part eq "2.1") {
            my $env         = $bodystruct->{bodystructure}->[$index]
                                ->{envelopestruct};
            my $filename    = $env->{subject};
            my $attachmsgid = $env->{messageid};
            push @{$msghash->{parts}->{$part}->{attachments}},{
                filename    => $filename,
                msg_id      => $attachmsgid,
                payload     => $body,
            };
        }
        else {
            $msghash->{parts}->{$part} = {
                type    => $bodysubtype,
                body    => $body,
            }
        }
    }
}

sub build_body {
    my $self        = shift;
    my $msg_href    = shift;
    my $body        = $msg_href->{parts}->{1}->{body};
    return $body;
}

sub parse_body {
    my $self    = shift;
    my $bhref   = shift;
    my $body    = $bhref->{html} // $bhref->{plain};
    my $log     = $self->env->log;
    my $data;

    $log->debug("parsing body");

    my %captures    = (
        envelope_from   => { name => "efa",     regex => $ENV_FROM_ADDR },
        header_from     => { name => "hfa",     regex => $HDR_FROM_ADDR },
        recipients      => { name => "rotm",    regex => $RECIPIENTS },
        gmt_time        => { name => "gtd",     regex => $GMT_TIME },
        subject         => { name => "sotm",    regex => $SUBJECT },
        size            => { name => "ms",      regex => $SIZE },
        details         => { name => "d",       regex => $DETAILS },
        attachments     => { name => "a",       regex => $ATTACHMENTS },
    );

    foreach my $capture (keys %captures) {
        my $name    = $captures{$capture}->{name};
        my $regex   = $captures{$capture}->{regex};

        $body           =~ m/$regex/g;
        $data->{$capture}  = $+{$name};

    }
    $log->debug("ALERT DATA is ".Dumper($data));

    return [$data], [qw( envelope_from header_from recipients gmt_time 
                     subject size details attachments)];
}

__PACKAGE__->meta->make_immutable;
1;
