#!/usr/bin/env perl
use v5.18;
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::App::Rss;
use Safe;


$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/rss.cfg.pl';
my $config_file = $ENV{'scot_config_file'};
my $env = Scot::Env->new({
    config_file => $config_file
});
my $feeds = $env->feeds;

my $rss = Scot::App::Rss->new({env => $env});

foreach my $feed (@$feeds) {
    my $url = $feed->{url};
    my $body = $rss->get_xml($url);
    ok(defined $body && $body ne '', "Retrieved Feed $feed->{name}:$url");
    my $data = $rss->parse_xml($body);
    
}
done_testing();


