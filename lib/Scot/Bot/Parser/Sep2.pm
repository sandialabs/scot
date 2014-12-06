package Scot::Bot::Parser::Sep2;

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

use Moose;
extends 'Scot::Bot::Parser';



sub parse_body {
    my $self    = shift;
    my $bhref   = shift;
    my $body    = $bhref->{html} // $bhref->{plain};
    my $log     = $self->env->log;
    my $data    = {};

    $log->debug("Parsing body");
    $log->debug("body is " . Dumper($body));

    my @lines = split /\012\015?|\015\012?/, $body;
    my @columns = ();

    $log->debug("lines are ".Dumper(@lines));
    
    foreach my $line (@lines) {
        $log->debug("line is $line");
        my ($key, $value) = split(/: /, $line, 2);
        next unless (defined $key);
        $log->debug("key = $key");
        $log->debug("value = $value");
        $key =~ s/ /_/g;
        $key =~ s/\./,/g;
        push @columns, $key;
        $data->{$key} = $value;
    }
    $log->debug("parsed data struct is :".Dumper($data));
    return [$data], \@columns;

}
__PACKAGE__->meta->make_immutable;
1;
