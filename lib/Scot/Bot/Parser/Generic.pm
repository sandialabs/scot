package Scot::Bot::Parser::Generic;

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

use Moose;
extends 'Scot::Bot::Parser';



sub parse_body {
    my $self        = shift;
    my $bodyhref    = shift;
    my $body        = $bodyhref->{html} // $bodyhref->{plain};
    my @columns     = qw(alert);
    my $data        = {
        alert   => $body,
        columns => \@columns,
    };
    return [$data], \@columns;
}

__PACKAGE__->meta->make_immutable;
1;
