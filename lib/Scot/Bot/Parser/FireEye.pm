package Scot::Bot::Parser::FireEye;

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
use List::Uniq ':all';
use JSON;

use Moose;
extends 'Scot::Bot::Parser';

sub parse_body {
    my $self        = shift;
    my $bodyhref    = shift;
    my $body        = $bodyhref->{plain};
    my $log         = $self->env->log;

    my $json    = JSON->new->relaxed(1);
    $body       =~ s/\012\015?|\015\012?//g;
    my $decoded;
    eval {
       $decoded = $json->decode($body);
    };
    my $html    = Dumper($decoded);

    my $data    = {
        fireeye_alert => $html,
    };
    return [ $data ], ["fireeye_alert"];
}



sub parse_body_old {
    my $self        = shift;
    my $bodyhref    = shift;
    my $body        = $bodyhref->{html} // $bodyhref->{plain};
    my $log     = $self->env->log;
    my $data    = {};

    $log->debug("parse body");
    $log->debug("body is " . Dumper($body));

    my @lines = split /\012\015?|\015\012?/, $body;
    my @columns = ();

    $log->debug("lines are ".Dumper(@lines));
    
    foreach my $line (@lines) {
        $log->debug("line is $line");
        my ($key, $value) = split(/:/, $line, 2);
        next unless (defined $key);
        $log->debug("key = $key");
        $log->debug("value = $value") if $value;
        $key =~ s/^ +//g;
        $key =~ s/ /_/g;
        $key =~ s/\./,/g;
        push @columns, $key;
        next if ( $key eq '' or ! defined $key );
        next if ( $key eq '--------------------------------------------------------------------------------');
        $data->{$key} = $value;
    }
    $log->debug("parsed data struct is :".Dumper($data));
    my @unique_columns = uniq @columns;
    return [$data], \@unique_columns;
}

__PACKAGE__->meta->make_immutable;
1;
