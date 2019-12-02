#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use Data::Dumper;
use Scot::Env;
use DateTime;
use HTML::TreeBuilder;
$| = 1;
my  $root   = "/opt/scot/public";

my $env = Scot::Env->new(
    config_file => '/opt/scot/etc/scot.cfg.pl'
);

my $mongo   = $env->mongo;
my $ecol    = $mongo->collection('Entry');
my $cursor  = $ecol->find({
});
$cursor->sort({id=>-1});
$cursor->immortal(1);

my $count   = 0;
my $fine    = 0;
while (my $entry = $cursor->next) {
    my $html    = $entry->body_flair;
    my $tree    = build_tree($html);
    my @images  = @{ $tree->extract_links('img') };
    
    foreach my $aref (@images) {
        my ( $link, $element, $attr, $tag ) = @{$aref};
        if ( $link =~ m/cached_images/ ) {
            my $file    = $root . $link;
            if ( ! -r $file ) {
                $count++;
                printf "%5d Entry %6d created %12s updated %12s => %s\n",
                        $count,
                        $entry->id,
                        get_human_date($entry->created),
                        get_human_date($entry->updated),
                        $file;

                printf "     Target %10s ID %10s\n", $entry->target->{type}, $entry->target->{id};
                $entry->update_set(parsed => 0);
                $env->mq->send('/topic/scot', {
                    action  => 'updated',
                    data    => {
                        who => 'scot-admin',
                        type => 'entry',
                        id  => $entry->id,
                    },
                });
                sleep 10;
            }
            else {
                printf "%5s Entry %6d cached image present\n", " ", $entry->id;
            }
        }
        else {
            printf "%5s Entry %6d no cached images\n", " ", $entry->id;
        }
    }

}

sub get_human_date {
    my $epoch   = shift;
    my $dt      = DateTime->from_epoch(epoch => $epoch);
    return join(' ',$dt->ymd, $dt->hms);
}

sub build_tree {
    my $body    = shift;
    my $tree    = HTML::TreeBuilder->new;
    $tree->implicit_tags(1);
    $tree->implicit_body_p_tag(1);
    $tree->p_strict(1);
    $tree->no_space_compacting(1);
    $tree->parse_content($body);
    $tree->elementify;
    return $tree;
}
