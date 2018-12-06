#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use v5.16;

my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('entry');
my $cursor      = $collection->find({class => "task"});

print "starting...\n";
print $cursor->count . " task records\n";
my %lookup  = ();

while (my $task = $cursor->next) {

    my $id       = $task->{id};
    print "...task $id\n";

    my $meta = $task->{metadata};

    if ( defined $meta ) {

        if ( defined $meta->{status} 
             && defined $meta->{when}
             && defined $meta->{who} ) {

            say "... ... has valid task meta structure";

            my $thref = {
                status  => $meta->{status},
                when    => $meta->{when},
                who     => $meta->{who},
            };

            delete $meta->{status};
            delete $meta->{when};
            delete $meta->{who};

            $meta->{task} = $thref;

            my $set     = {
                metadata    => $meta
            };

            $collection->update_one(
                {id => $id},
                {'$set' => $set }
            );
            say  "Update == ".Dumper($set);
        }
    }
}
