#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Test::More;
use Scot::Env;
use Scot::Util::Imap;
use Scot::Util::Imap::Cursor;
use Data::Dumper;

#my $env     = Scot::Env->new();
#my $imap    = $env->imap;

#my $cursor  = $imap->get_since_cursor({ hour => 5});
#say "got ".$cursor->count." uids";
#while ( my $uid = $cursor->next ) {
#    say "got uid = $uid";
#    my $href = $imap->get_message($uid,1);
#    say "Press <enter>";
#    my $foo = <STDIN>;
#}
exit 0;

#$cursor  = $imap->get_unseen_cursor();
#
#while ( my $uid = $cursor->next ) {
#    say "Got uid $uid";
#    my $href    = $imap->get_message($uid,1);
#    say Dumper($href);
#    say "Press <enter>";
#    my $foo = <STDIN>;
#}
#

say "done";
