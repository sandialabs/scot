#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use Data::Dumper;
use Scot::Env;
use IO::Prompt;
use DateTime::Format::Strptime;
use DateTime;
use v5.16;

use strict;
use warnings;

my $env   = Scot::Env->new(config_file=>'/opt/scot/etc/scot.cfg.pl');
my $mongo = $env->mongo;


print "-----------------------------------------------------\n";
print "$0 : Modify permissions on existing SCOT records\n";
print "-----------------------------------------------------\n\n";

print "Select Collection to Modify\n";

prompt -menu => {
    Alertgroup  => 'Alertgroup',
    Alert       => 'Alert',
    Checklist   => 'Checklist',
    Entry       => 'Entry',
    Event       => 'Event',
    File        => 'File',
    Guide       => 'Guide',
    Incident    => 'Incident',
    Intel       => 'Intel',
    Signature   => 'Signature',
};
my $collection_name = $_;

my $col = $mongo->collection(ucfirst($collection_name));

if ( ! defined $col ) {
    die "Invalid collection.\n";
}

print "querying db for id range in $collection_name...\n";

my $max_id  = $col->count();

my $start_id        = prompt("Enter starting id of range you wish to modify > ", -d => 0) + 0;
my $end_id          = prompt("Enter ending id of range you wish to modify ] > ", -d => $max_id) + 0;

my $start_date;
my $end_date;
my $noid;

if ( $start_id  == 0 and $end_id == $max_id ) {
    print "This will modify all records in $collection_name\n";
    $noid++;
    my $rbdr    = prompt("Do you wish to restrict records by date range", -d => "no");
    if ( $rbdr ne "no" ) {
        $start_date = prompt("Enter Start DateTime [MM-dd-yyyy hh:mm:ss] > ");
        $end_date   = prompt("Enter End   DateTime [MM-dd-yyyy hh:mm:ss] > ");
    }
}

print "What do you wish to do?\n";

prompt -menu => {
    "Alter READ permissions"    => "read",
    "Alter MODIFY permissions"  => "modify",
    "Alter BOTH"                => "both",
};
my $rmb = $_;

print "How do you wish to alter $rmb permissions?\n";

prompt -menu => {
    "Add groups"        => "add",
    "Overwrite groups"  => "overwrite",
    "Delete groups"     => "del",
};
my $action  = $_;

my $add_groups;

if ( $action eq "add" ) {
    $add_groups = prompt("Enter comma seperated list of groups to add \n> ");
}

my $over_groups;

if ( $action eq "overwrite" ) {
    $over_groups = prompt("Enter comma seperated list of groups to replace existing \n> ");
}

my $delete_groups;

if ( $action eq "del" ) {
    $delete_groups = prompt("Enter comma seperated list of groups to remove if they exist\n>");
}

print "==========================================\n";
print "= Verification                           =\n";
print "==========================================\n";
print "= Collection      => $collection_name\n";
print "= Start Id        => $start_id\n";
print "= End   Id        => $end_id\n";
print "= Start Date      => $start_date\n" if (defined $start_date);
print "= End   Date      => $end_date\n" if (defined $end_date);
print "= Target          => $rmb\n";
print "= add groups      => $add_groups\n" if (defined $add_groups);
print "= overwrite groups=> $over_groups\n" if (defined $over_groups);
print "= delete groups   => $delete_groups\n" if (defined $delete_groups);
print "==========================================\n";

my $proceed = prompt("Do you wish to proceed? ", -d => "yes");

if ( $proceed ne "yes" ) {
    die "Changes aborted...\n";
}

my $match   = {
    id  => { '$gte' => $start_id },
    id  => { '$lte' => $end_id },
};

if ( defined $start_date ) {
    my $start_epoch = get_epoch($start_date);
    $match->{created} = { '$gte' => $start_epoch };
}

if ( defined $end_date ) {
    my $end_epoch = get_epoch($end_date);
    $match->{created} = { '$lte' => $end_epoch };
}

my $hitcount    = $col->count($match);
my $cursor      = $col->find($match);
my $completed   = 0;

print "Found $hitcount matches,...\n";

while ( my $obj = $cursor->next ) {
    print "$action Updating permissions on $rmb id ".$obj->id."\n";
    if ( $action eq "add" ) {
        print "Add groups = $add_groups\n";
        my @groups = split(/,[ ]*/,$add_groups);
        print Dumper(@groups)."\n";
        if ( $rmb eq "read" or $rmb eq "both" ) {
            add_groups($obj, "groups.read", \@groups);
        }
        if ( $rmb eq "modify" or $rmb eq "both" ) {
            add_groups($obj, "groups.modify", \@groups);
        }
    }
    if ( $action eq "del" ) {
        my @groups = split(/,[ ]*/,$delete_groups);
        if ( $rmb eq "read" or $rmb eq "both" ) {
            del_groups($obj, "groups.read", \@groups);
        }
        if ( $rmb eq "modify" or $rmb eq "both" ) {
            del_groups($obj, "groups.modify", \@groups);
        }
    }
    if ( $action eq "overwrite" ) {
        my @groups = split(/,[ ]*/,$over_groups);
        my $href    = {};
        if ( $rmb eq "read" or $rmb eq "both" ) {
            $href->{groups}->{read} = \@groups;
        }
        if ( $rmb eq "modify" or $rmb eq "both" ) {
            $href->{groups}->{modify} = \@groups;
        }
        print "modify href ".Dumper($href)."\n";
        $obj->update({'$set' => $href });
    }
    $completed++;
    print "$completed of $hitcount processed...\r";
}

sub get_epoch {
    my $date    = shift;
    my $stptime = DateTime::Format::Strptime->new(
        pattern => '%m/%d/%Y %T',
        locale  => 'en_US',
        time_zone   => 'America/Denver',
        on_error    => 'croak',
    );
    my $dt = $stptime->parse_datetime($date);
    return $dt->epoch;
}

sub add_groups {
    my $obj     = shift;
    my $type    = shift;
    my $aref    = shift;

    foreach my $g (@$aref) {
        $obj->update_add($type => $g);
    }
}

sub del_groups {
    my $obj     = shift;
    my $type    = shift;
    my $aref    = shift;

    foreach my $g (@$aref) {
        print "removing $g from $type...\n";
        $obj->update_remove($type => $g);
    }
}


    

