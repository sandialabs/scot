package Scot::App::Topdomains;

use lib '../../../lib';
use strict;
use warnings;

use Data::Dumper;
use Moose;
extends 'Scot::App';


sub run {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("Updating topdomain collection...");

    my $query   = { type => "domain", status => "tracked" };
    my $total   = $mongo->collection('Entity')->count($query);
    my $touched = 0;
    my $processed   = 0;
    my $cursor  = $mongo->collection('Entity')->find($query);
    my $lincol  = $mongo->collection('Link');
    my $dscol   = $mongo->collection('Domainstat');

    while ( my $entity = $cursor->next ) {
        my $eid     = $entity->id;
        my $count   = $lincol->get_display_count($entity);
        my $bldata  = $entity->data->{blocklist3};
        $bldata     = {} if (! defined $bldata );
        my $row     = {
            entity_id   => $eid,
            value       => $entity->value,
            count       => $count,
            entries     => $entity->entry_count,
            blocklist   => $bldata,
        };
        $log->trace("upserting ",{filter=>\&Dumper, value=>$row});
        my $result  = $self->upsert_domain_data($row);
        $log->trace("upsert domain result = ",{filter => \&Dumper, value => $result});
        $touched++;
        $processed++;
        if ( $touched > 9999 ) {
            $log->debug("$processed of $total processed");
            $touched = 0;
        }
    }
}

sub upsert_domain_data {
    my $self    = shift;
    my $row     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $dscol   = $mongo->collection('Domainstat');

    my $match   = { entity_id => $row->{entity_id} };
    my $obj     = $dscol->find_one($match);
    my $result  = '';

    unless ( defined $obj ) {
        my $new = $dscol->create($row);
        $result = 'created domainstat '.$new->id;
    }
    else {
        $obj->update({
            '$set'  => $row
        });
        $result = 'updated domainstat '.$obj->id;
    }

}
