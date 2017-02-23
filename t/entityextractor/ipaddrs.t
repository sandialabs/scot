#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::EntityExtractor;
use Scot::Util::Config;
use Scot::Util::LoggerFactory;
my $logfactory = Scot::Util::LoggerFactory->new({
    config_file => 'logger_test.cfg',
    paths       => [ '../../../Scot-Internal-Modules/etc' ],
});
my $log = $logfactory->get_logger;

my $extractor   = Scot::Util::EntityExtractor->new({log=>$log});

my @ipaddrs = ( 
    { 
        source  => '10.10.10.2', 
        flair   => '<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.2">10.10.10.2</span> </div>',
        plain   => '10.10.10.2',
        entity  => [ { type  => 'ipaddr', value => '10.10.10.2' } ],
    },
    { 
        source  => '10[.]10[.]10[.]2', 
        flair   => '<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.2">10.10.10.2</span> </div>',
        plain   => '10.10.10.2',
        entity  => [ { type  => 'ipaddr', value => '10.10.10.2' } ],
    },
    { 
        source  => '10{.}10{.}10{.}2', 
        flair   => '<div><span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.2">10.10.10.2</span> </div>',
        plain   => '10.10.10.2',
        entity  => [ { type  => 'ipaddr', value => '10.10.10.2' } ],
    },
    { 
        source  => 'https://10.10.10.2/foo/bar', 
        flair   => '<div>https://<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.2">10.10.10.2</span>/foo/bar </div>',
        plain   => 'https://10.10.10.2/foo/bar',
        entity  => [ { type  => 'ipaddr', value => '10.10.10.2' } ],
    },
);

foreach my $href (@ipaddrs) {

    my $result  = $extractor->process_html($href->{source});
    is($result->{text}, $href->{plain}, "For $href->{source}, plain text is correct");
    is($result->{flair}, $href->{flair}, "For $href->{source}, flair html is corrent");
    cmp_bag($result->{entities}, $href->{entity}, "For $href->{source}, entities are correct");

}

done_testing();
exit 0;
