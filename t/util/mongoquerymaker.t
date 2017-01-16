#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Test::More;
use Test::Deep;
use Scot::Util::MongoQueryMaker;
use Data::Dumper;

my $mqm = Scot::Util::MongoQueryMaker->new();

my @tests   = (
    {
        name    => "in order epochs",
        params  => { "updated"   => [ 1472165112,1472165113 ], },
        match   => {
            updated => {
                '$lte'  => 1472165113,
                '$gte'  => 1472165112
            }
        }
    },
    {
        name    => "out of order epochs",
        params  => { "updated"   => [ 1472165113,1472165112], },
        match   => {
            updated => {
                '$lte'  => 1472165113,
                '$gte'  => 1472165112
            }
        }
    },
    {
        name    => "too many epochs",
        params  => { "updated"   => [ 1472165113,1472165112,1472165114], },
        match   => {
            updated => {
                '$lte'  => 1472165114,
                '$gte'  => 1472165112
            }
        }
    },
    {
        name    => "not enough epochs",
        params  => { "updated"   =>  14721651134 , },
        match   => {
            updated => {
                error   => "invalid datefield match string"
            }
        }
    },
    {
        name    => "numeric single value",
        params  => { "views"  => 4 },
        match   => {
            views   => 4
        }
    },
    { 
        name    => "attempted non-numeric match",
        params  => { "views"    => "a" },
        match   => { views => { error => "need numbers for numeric match" } },
    },
    {
        name    => "negative single value match",
        params  => { "views" => "!4" },
        match   => { views => { '$ne' => 4 } },
    },
    {
        name    => "numeric array match",
        params  => { "views"    => [ 1, 2, 3, 4] },
        match   => { views => { '$in' => [ 1, 2, 3, 4 ] }},
    },
    {
        name    => "numeric negated array match",
        params  => { "views"    => [ 1, '!2', 3, 4] },
        match   => { views => { '$nin' => [ 1, 2, 3, 4 ] }},
    },
    {
        name    => "expression match 1",
        params  => { "views"    => '4<=x<=10' },
        match   => { views => { '$gte' => 4, '$lte' => 10 } },
    },
    {
        name    => "expression match 2",
        params  => { "views"    => '40>=x>=1' },
        match   => { views => { '$gte' => 1, '$lte' => 40 } },
    },
    {
        name    => "expression match 3",
        params  => { "views"    => '4<x<10' },
        match   => { views => { '$gt' => 4, '$lt' => 10 } },
    },
    {
        name    => "expression match 4",
        params  => { "views"    => '40>x>1' },
        match   => { views => { '$gt' => 1, '$lt' => 40 } },
    },
    {
        name    => "expression match 5",
        params  => { "views"    => '4<=x<10' },
        match   => { views => { '$gte' => 4, '$lt' => 10 } },
    },
    {
        name    => "expression match 6",
        params  => { "views"    => '40>x>=1' },
        match   => { views => { '$gte' => 1, '$lt' => 40 } },
    },
    {
        name    => "invalid expression match 1",
        params  => { "views"    => '40>x=1' },
        match   => { views => { error => 'invalid numeric match expression' } },
    },
    {
        name    => "invalid expression match 2",
        params  => { "views"    => '40x=1' },
        match   => { views => { error => 'invalid numeric match expression' } },
    },
    {
        name    => "invalid expression match 3",
        params  => { "views"    => '40<<x<=1' },
        match   => { views => { error => 'invalid numeric match expression' } },
    },
    {
        name    => "straight up greater than match",
        params  => { "views"    => 'x>2' },
        match   => { views  => { '$gt' => 2 } },
    },
    {
        name    => "straight up less than match",
        params  => { "views"    => 'x<2' },
        match   => { views  => { '$lt' => 2 } },
    },


);

foreach my $test (@tests) {
    my $generated = $mqm->build_match_ref($test->{params});
    cmp_deeply($generated, $test->{match}, $test->{name});
}

    

          
done_testing();
exit 0;
