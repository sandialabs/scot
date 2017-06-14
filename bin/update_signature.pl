#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;

my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('signature');
my $cursor      = $collection->find();
my $bodycol     = $mongo->get_collection('sigbody');

print "starting...\n";
print $cursor->count . " signature records\n";

while (my $signature = $cursor->next) {

    my $id       = $signature->{id};
    print "...signature $id\n";
    my $sbcur    = $bodycol->find({signature_id  => $id});
    my $revision_count   = 0;

    if ( defined $sbcur ) {
        $sbcur->sort({created => 1});

        while (my $sigbody = $sbcur->next ) {
            $revision_count++;
            my $sbid    = $sigbody->{id};
	    print "......sigbody $sbid\n";
            $bodycol->update_one(
                {id => $sbid},
                {'$set' => {revision => $revision_count}}
            );
        }

    }

    my $siggroup = $signature->{signature_group};

    $collection->update_one(
        {id => $id},
        {'$set' => {
            latest_revision => $revision_count,
            signature_group => $siggroup ,
        }}
    );
}
