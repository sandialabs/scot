#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;

my $mongo       = MongoDB->connect->db('scot-prod');
my $collection  = $mongo->get_collection('signature');
my $cursor      = $collection->find();
my $bodycol     = $mongo->get_collection('sigbody');

print "starting...\n";
print $cursor->count . " signature records\n";
my %lookup  = ();

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
            $lookup{$sbid} = $revision_count;
            print "......sigbody $sbid beomes rev $revision_count\n";
            $bodycol->update_one(
                {id => $sbid},
                {'$set' => {revision => $revision_count}}
            );
        }

    }

    my $siggroup = $signature->{signature_group};
    my $prod_id  = $signature->{prod_sigbody_id};
    my $qual_id  = $signature->{qual_sigbody_id};

    my $set_href    = {
            latest_revision => $revision_count,
    #        signature_group => $siggroup,
            prod_sigbody_id => $lookup{$prod_id} // 0,
            qual_sigbody_id => $lookup{$qual_id} // 0,
        };


    if ( ref($siggroup) eq "ARRAY" ) {
        print "... ... signature_group already converted to array\n";
    }
    else {
        $set_href->{signature_group} = [ $siggroup ];
    }

    $collection->update_one(
        {id => $id},
        {'$set' => $set_href }
    );
}
