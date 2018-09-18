#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use lib '../lib';
use Scot::Env;
use IO::Prompt;
use v5.18;

my $continue    = "no";
my $env         = Scot::Env->new({config_file => "/opt/scot/etc/scot.cfg.pl"});
my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('incident');
my $cursor      = $collection->find({});
$cursor->sort({id   => -1});

print "starting...\n";
print $collection->count() . " incident records\n";

my $forms    = $env->forms;
my @newincidents;
while (my $incident = $cursor->next) {

    say "Incident ".$incident->{id};

    my $version = $incident->{data_fmt_ver};
    my $form    = $forms->{$version};

    foreach my $element (@$form) {
        my $key     = $element->{key};
        my $value   = delete $incident->{$key};

        $incident->{data}->{$key} = $value;

    }

    say Dumper($incident);
    if ($continue eq "no" ) {
        my $cont    = prompt("Continue: [enter] once, [GO] till end > ");
        if ( $cont eq "GO" ) {
            $continue = "yes";
        }
    }

    $collection->delete_one({id => $incident->{id}});
    push @newincidents, $incident;
}

$collection->insert_many([@newincidents]);

say "Working on Guides";
$continue = "no";

$collection = $mongo->get_collection('guide');
$cursor     = $collection->find({});
say $collection->count() .  " Guide Records";
my @newguides = ();
while ( my $guide = $cursor->next) {

    say "Guide ".$guide->{id};
    my $version = $guide->{data_fmt_ver} // 'guide';
    my $form    = $forms->{$version};

    foreach my $element ( @$form ) {
        my $key = $element->{key};
        my $val = delete $guide->{$key};
        $guide->{data}->{$key} = $val;
    }

    say Dumper($guide);
    if ($continue eq "no" ) {
        my $cont    = prompt("Continue: [enter] once, [GO] till end > ");
        if ( $cont eq "GO" ) {
            $continue = "yes";
        }
    }
    $collection->delete_one({id => $guide->{id}});
    push @newguides, $guide;
}
$collection->insert_many([@newguides]);

say "Working on Signatures";
$continue = "no";

$collection = $mongo->get_collection('signature');
$cursor     = $collection->find({});
say $collection->count(). " Signatures";
my @newsigs = ();
while (my $sig = $cursor->next) {
    say "Signature ".$sig->{id};
    my $version = $sig->{data_fmt_ver} // 'signature';
    my $form    = $forms->{$version};

    foreach my $element ( @$form ) {
        my $key = $element->{key};
        if ( $key =~ /\./ ) {
            my ($akey,$skey) = split(/\./,$key);
            $sig->{data}->{$akey}->{$skey} = $sig->{$key};
        }
        else {
            my $val = delete $sig->{$key};
            $sig->{data}->{$key} = $val;
        }
    }

    say Dumper($sig);
    if ($continue eq "no" ) {
        my $cont    = prompt("Continue: [enter] once, [GO] till end > ");
        if ( $cont eq "GO" ) {
            $continue = "yes";
        }
    }
    $collection->delete_one({id => $sig->{id}});
    push @newsigs, $sig;
}
$collection->insert_many([@newsigs]);
