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

my @sources = ( 
    { 
        source  => 'www.google.com', 
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
        plain   => 'www.google.com',
        entity  => [ { type  => 'domain', value => 'www.google.com' } ],
    },
    {
        source  => 'www(.)google(.)com', 
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
        plain   => 'www.google.com',
        entity  => [ { type  => 'domain', value => 'www.google.com' } ],
    },
    {
        source  => 'www[.]google[.]com', 
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
        plain   => 'www.google.com',
        entity  => [ { type  => 'domain', value => 'www.google.com' } ],
    },
    {
        source  => 'www{.}google{.}com', 
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="www.google.com">www.google.com</span> </div>',
        plain   => 'www.google.com',
        entity  => [ { type  => 'domain', value => 'www.google.com' } ],
    },
    {
        source  => 'https://cbase.som.sunysb.edu/foo/bar',
        flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/foo/bar </div>',
        plain   => 'https://cbase.som.sunysb.edu/foo/bar',
        entity  => [ { type => 'domain', value => 'cbase.som.sunysb.edu' } ],
    },
    {
        source  => 'https://cbase(.)som[.]sunysb{.}edu/foo/bar',
        flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="cbase.som.sunysb.edu">cbase.som.sunysb.edu</span>/foo/bar </div>',
        plain   => 'https://cbase.som.sunysb.edu/foo/bar',
        entity  => [ { type => 'domain', value => 'cbase.som.sunysb.edu' } ],
    },
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
    { 
        source  => 'foo.10.com', 
        flair   => '<div><span class="entity domain" data-entity-type="domain" data-entity-value="foo.10.com">foo.10.com</span> </div>',
        plain   => 'foo.10.com',
        entity  => [ { type  => 'domain', value => 'foo.10.com' } ],
    },
    {
        source  => 'servicehst.exe',
        flair   => '<div><span class="entity file" data-entity-type="file" data-entity-value="servicehst.exe">servicehst.exe</span> </div>',
        plain   => 'servicehst.exe',
        entity  => [ { type => 'file', value => 'servicehst.exe' } ],
    },
    {
        source  => 'webadmin.php',
        flair   => '<div><span class="entity file" data-entity-type="file" data-entity-value="webadmin.php">webadmin.php</span> </div>',
        plain   => 'webadmin.php',
        entity  => [ { type => 'file', value => 'webadmin.php' } ],
    },
    {
        source  => 'scot-dev@watermelon.gov',
        flair   => '<div><span class="entity email" data-entity-type="email" data-entity-value="scot-dev@watermelon.gov">scot-dev@watermelon.gov</span> </div>',
        plain   => 'scot-dev@watermelon.gov',
        entity  => [ { type => 'email', value => 'scot-dev@watermelon.gov' } ],
    },
    {
        source  => 'dffdb29b64e355a0ef29843e68c23b4f',
        flair   => '<div><span class="entity md5" data-entity-type="md5" data-entity-value="dffdb29b64e355a0ef29843e68c23b4f">dffdb29b64e355a0ef29843e68c23b4f</span> </div>',
        plain   => 'dffdb29b64e355a0ef29843e68c23b4f',
        entity  => [ { type => 'md5', value => 'dffdb29b64e355a0ef29843e68c23b4f' } ],
    },
    {
        source  => 'dffdb29b64e355a0ef29843e68c23b4f',
        flair   => '<div><span class="entity md5" data-entity-type="md5" data-entity-value="dffdb29b64e355a0ef29843e68c23b4f">dffdb29b64e355a0ef29843e68c23b4f</span> </div>',
        plain   => 'dffdb29b64e355a0ef29843e68c23b4f',
        entity  => [ { type => 'md5', value => 'dffdb29b64e355a0ef29843e68c23b4f' } ],
    },
    {
        source  => 'dffdb29b64e355a0ef29843e68c23b4fabcdef12',
        flair   => '<div><span class="entity sha1" data-entity-type="sha1" data-entity-value="dffdb29b64e355a0ef29843e68c23b4fabcdef12">dffdb29b64e355a0ef29843e68c23b4fabcdef12</span> </div>',
        plain   => 'dffdb29b64e355a0ef29843e68c23b4fabcdef12',
        entity  => [ { type => 'sha1', value => 'dffdb29b64e355a0ef29843e68c23b4fabcdef12' } ],
    },
    {
        source  => 'de5b53a49ce40e546cc26e9727127aa4623a6f9d2c31ba2f15755c547f0a2c11',
        flair   => '<div><span class="entity sha256" data-entity-type="sha256" data-entity-value="de5b53a49ce40e546cc26e9727127aa4623a6f9d2c31ba2f15755c547f0a2c11">de5b53a49ce40e546cc26e9727127aa4623a6f9d2c31ba2f15755c547f0a2c11</span> </div>',
        plain   => 'de5b53a49ce40e546cc26e9727127aa4623a6f9d2c31ba2f15755c547f0a2c11',
        entity  => [ { type => 'sha256', value => 'de5b53a49ce40e546cc26e9727127aa4623a6f9d2c31ba2f15755c547f0a2c11' } ],
    },
    {
        source  => '__utma=111111111.111111111.1111111112.1111111112.1111111112.3;',
        flair   => '<div><span class="entity ganalytics" data-entity-type="ganalytics" data-entity-value="__utma=111111111.111111111.1111111112.1111111112.1111111112.3;">__utma=111111111.111111111.1111111112.1111111112.1111111112.3;</span> </div>',
        plain   => '__utma=111111111.111111111.1111111112.1111111112.1111111112.3;',
        entity  => [ { type => 'ganalytics', value => '__utma=111111111.111111111.1111111112.1111111112.1111111112.3;'} ],
    },
    {
        source  => 'S939456',
        flair   => '<div><span class="entity snumber" data-entity-type="snumber" data-entity-value="S939456">S939456</span> </div>',
        plain   => 'S939456',
        entity  => [ { type => 'snumber', value => 'S939456', } ],
    },

);

foreach my $href (@sources) {

    my $result  = $extractor->process_html($href->{source});
    is($result->{text}, $href->{plain}, "For $href->{source}, plain text is correct");
    is($result->{flair}, $href->{flair}, "For $href->{source}, flair html is corrent");
    cmp_bag($result->{entities}, $href->{entity}, "For $href->{source}, entities are correct");

}

done_testing();
exit 0;
    

