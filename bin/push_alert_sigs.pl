#!/usr/bin/env perl

use lib '../lib';
use strict;
use warnings;
use Scot::Env;
use Data::Dumper;
use HTML::TreeBuilder;
use IO::Prompt;

my $env = Scot::Env->new({
    config_file => '/opt/scot/etc/scot.cfg.pl'
});

my $log = $env->log;
$log->debug("----- Starting Splunk Alert to Signature Migration -----");

my $mongo   = $env->mongo;
my $col     = $mongo->collection('Alert');
my $sigcol  = $mongo->collection('Signature');
my $sbcol   = $mongo->collection('Sigbody');
my $cursor  = $col->find({
    subject => qr/^Splunk/,
    "data.search" => {
        '$ne'   => undef
    }
});
$cursor->immortal(1);

my %owner_lookup    = (
    ANP     => 'anpease',
    AAQ     => 'aaquint',
    AJB     => 'ajberry',
    'AJB-'  => 'ajberry',
    BUBBLE  => 'BUBBLE',
    'DMA-'  => 'dmantho',
    'DMA'   => 'dmantho',
    'DMA and WD' => 'dmantho',
    SMYG    => 'sygalvi',
    JCJ     => 'jcjaroc',
    JDM     => 'jdmaine',
    JJM     => 'jjmande',
    KRG     => 'kgurule',
    MJY     => 'mjyates',
    'MJY-'  => 'mjyates',
    Troy    => 'tdevrie',
    SIL     => 'enhan',
    WKL     => 'wklee',
    TB      => 'tbruner',
    JJH     => 'jjhaas',
    TD      => 'tdean',
    TMR     => 'tmreed',
    NRP     => 'nrpeter',
    RAS     => 'rasuppo',
    RAU     => 'rauhric',
    ST      => 'sty',           # Sereyvanthana Ty
    SMYG    => 'sygalvi',
    JCS     => 'jcstrom',

);

my %seen    = ();


ALERT:
while ( my $alert = $cursor->next ) {
    # print Dumper({$alert->as_hash});
    my $name = $alert->subject;
    my $subject;
    my $owner;

    ($owner, $subject) = $name =~ m/^Splunk Alert:[ ]*\((.*?)\) (.*)$/;

    if ( defined $seen{$subject} ) {
        print ".";
        next ALERT;
    }

    $seen{$subject}++;

    my $newname = "($owner) $subject"; # dont move the cheese
    my $username    = translate_owner($owner);

    my %signature   = (
        name            => $newname,
        status          => 'enabled',
        data_fmt_ver    => 'splunkalert',
        data            => {
            type        => 'splunk',
            description => 'Splunk Alert',
            action      => [ 'alert' ],
            tags        => [ $owner ],
            owner       => $username,
            groups      => {
                read    => [ 'wg-scot-ir', 'wg-scot-researchers' ],
                modify  => [ 'wg-scot-ir', ],
            },
            status      => 'enabled',
        },
    );

    my $sigobj  = $sigcol->api_create({
        user    => 'scot-admin',
        request => {
            json    => \%signature
        }
    });

    if ( ! defined $sigobj ) {
        print STDERR "Failed to create ".Dumper(\%signature)."\n";
        next ALERT;
    }

    my $bodyobj = $sbcol->api_create({
        request => {
            json    => {
                signature_id    => $sigobj->id,
                body            => $alert->data->{search},
            }
        }
    });
    print "+";
}
print "\n";

open (my $fh, ">", "./initials.txt");
print $fh Dumper(\%owner_lookup);
close ($fh);

sub translate_owner {
    my $initials     = shift;
    my $username;

    if ( defined $owner_lookup{$initials} ) {
        $username = $owner_lookup{$initials};
    }
    else {
        print "User $initials, not in lookup table\n";
        prompt "Enter username: ";
        $username = $_;
        $owner_lookup{$initials} = $username;
    }
    return $username;
}
   

