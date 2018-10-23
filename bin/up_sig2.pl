#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use IO::Prompt;
use v5.18;
use strict;
use warnings;

my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('signature');
my $cursor      = $collection->find();
my $bodycol     = $mongo->get_collection('sigbody');
my $continue    = "no";
my @delids      = ();
my @new         = ();

print "starting...\n";
print $cursor->count . " signature records\n";
my %lookup  = ();

while (my $signature = $cursor->next) {

    my $newsig  = {
        id              => $signature->{id},
        name            => $signature->{name},
        status          => $signature->{status},
        latest_revision => get_latest_revision($signature),
        stats           => {},
        options         => {},
        groups          => $signature->{groups},
        owner           => $signature->{owner},
        entry_count     => $signature->{entry_count},
        updated         => $signature->{updated} + 0,
        created         => $signature->{created} + 0,
        when            => $signature->{when} + 0,
        source          => $signature->{source} // [],
        tag             => $signature->{tag} // [],
        tlp             => $signature->{tlp} // 'unset',
        location        => $signature->{location},
        data_fmt_ver    => "signature",
        data            => {
            type            => $signature->{type},
            description     => $signature->{description},
            signature_group => $signature->{signature_group},
            prod_sigbody_id => $signature->{prod_sigbody_id} + 0,
            qual_sigbody_id => $signature->{qual_sigbody_id} + 0,
            action          => $signature->{action},
            target          => {
                type    => $signature->{target}->{type},
                id      => $signature->{target}->{id} + 0,
            },
        },
    };

    say "Old Signature";
    say Dumper($signature);
    say "New Signature";
    say Dumper($newsig);

    my $command = "go";
    if ( $continue eq "no" ) {
        my $response    = prompt("Make Swap: [All], [enter] once, [no] skip>");

        if ( $response =~ /all/i ) {
            $continue = "yes";
        }
        if ( $response =~ /no/i ) {
            $command = "skip";
        }
    }
    if ( $command eq "skip" ) {
        next;
    }
    push @delids, $signature->{id};
    push @new, $newsig;
}

$collection->delete_many({ id => {'$in' => \@delids }});
$collection->insert_many([@new]);

sub get_latest_revision {
    my $sig = shift;

    my $col = $mongo->get_collection('Sigbody');
    my $cur = $col->find({signature_id  => $sig->{id}});
    my $max = 0;

    while ( my $href = $cur->next ) {
        if ( $href->{revision} > $max ) {
            $max = $href->{revision} + 0;
        }
    }
    return $max;
}

