#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use v5.18;

my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('incident');
my $cursor      = $collection->find({});

print "starting...\n";
print $cursor->count . " incident records\n";
my %lookup  = ();

while (my $incident = $cursor->next) {

    my $id       = $incident->{id};
    print "...incident $id\n";

    my %data    = (
        reportable          => $incident->{reportable},
        type                => $incident->{type},
        category            => $incident->{category},
        security_category   => $incident->{security_category},
        sensitivity         => $incident->{sensitivity},
        doe_report_id       => $incident->{doe_report_id},
    );

    my %newinc  = (
        id              => $id,
        created         => $incident->{created},
        updated         => $incident->{updated},
        occurred        => $incident->{occurred},
        discovered      => $incident->{discovered},
        reported        => $incident->{reported},
        when            => $incident->{when} // 0,
        subject         => $incident->{subject},
        promoted_from   => $incident->{promoted_from},
        data_fmt_ver    => "incident_v2",
        data            => \%data,
    );

    $collection->update_one({id => $id}, \%newinc);

}
