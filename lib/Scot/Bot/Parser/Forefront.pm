package Scot::Bot::Parser::Forefront;

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



sub parse_body {
    my $self        = shift;
    my $bodyhref    = shift;
    my $body        = $bodyhref->{html} // $bodyhref->{plain};
    my $log         = $self->env->log;

    $log->debug("Parsing body");
    # $log->debug("body is ".Dumper($body));

    my $data    = {};
    my @columns = ();

    my %upper   = $body =~ m/[ ]{4}(.*?):[ ]+\"(.*?)\"/gms;
    my %lower   = $body =~ m/[ ]{6}(.*?):[ ]*(.*?)$/gms;

    foreach my $href (\%upper, \%lower) {
        while ( my ($k, $v) = each %$href ) {
            $k  =~ s/^[ \n\r]+//gms;
            $k  =~ s/ /_/g;
            $k  =~ s/\./_/g;
            push @columns, $k;
            $data->{$k} = $v;
        }
    }

    $log->debug("data is " . Dumper($data));
    return [$data], \@columns;
}

__PACKAGE__->meta->make_immutable;
1;
