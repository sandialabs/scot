#!/usr/bin/env perl

use MongoDB;

my $mongo       = MongoDB->connect->db('scotng-prod');
my $collection  = $mongo->get_collection('signature');
my $cursor      = $collection->find();
my $bodycol     = $mongo->get_collection('sigbody');

while (my $signature = $cursor->next) {

    my $id       = $signature->{id};
    my $sbcur    = $bodycol->find({signature_id  => $id});
    my $revision_count   = 0;

    if ( defined $sbcur ) {
        $sbcur->sort({created => 1});

        while (my $sigbody = $sbcur->next ) {
            $revision_count++;
            my $sbid    = $sigbody->{id};
            $sbcur->update_one(
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
            signature_group => [ $siggroup ],
        }}
    );
}
