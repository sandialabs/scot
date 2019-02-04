#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use Scot::Env;
use IO::Prompt;
use v5.16;

my $continue    = "no";
my $env         = Scot::Env->new({config_file => "/opt/scot/etc/scot.cfg.pl"});
my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('incident');
# my $cursor      = $collection->find({id=> {'$in'=> [267,266,265,264]}});
my $cursor      = $collection->find();
$cursor->sort({id   => -1});

print "starting...\n";
print $collection->count() . " incident records\n";

my $forms    = $env->forms;
my @newincidents;

while (my $incident = $cursor->next) {

    say "Incident ".$incident->{id};
    my $version = $incident->{data_fmt_ver};

    # 3 versions of incident
    # 1.  incdent
    # 2.  incident_v2
    # 3.  null

    if ( ! defined $version  ) {
        say "really messed up incident.  no data_fmt_ver attribute";
        my $form    = $forms->{incident};
        $incident->{data_fmt_ver}   = "incident";
        foreach my $element (@$form) {
            my $key     = $element->{key};
            my $value   = delete $incident->{$key};
            say "\t moving $key = $value to data";
            $incident->{data}->{$key} = $value;
        }
    }
    elsif ( $version eq "incident" ) {
        say "verson 1 incident, updating...";
        my $form    = $forms->{incident};
        foreach my $element (@$form) {
            my $key     = $element->{key};
            my $value   = delete $incident->{$key};
            say "\t moving $key = $value to data";
            $incident->{data}->{$key} = $value;
        }
    }
    else {
        say "version2 incident, updating ...";
        my $form    = $forms->{incident_v2};
        foreach my $element (@$form) {
            my $key     = $element->{key};
            my $value   = delete $incident->{$key};
            say "\t moving $key = $value to data";
            $incident->{data}->{$key} = $value;
        }
    }

    say Dumper($incident);

    if ( $continue eq "no" ) {
        my $mc  = prompt("Make change? [enter] yes, [n] no >");
        if ($mc eq "yes") {
            $continue = "yes";
        }
        if ($mc eq "n") {
            next;
        }
    }

    $collection->delete_one({id => $incident->{id}});
    $collection->insert_one($incident);
}

