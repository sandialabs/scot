#!/usr/bin/env perl
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Scot::Util::EntityExtractor;

my $extractor   = Scot::Util::EntityExtractor->new();

my @domains = ( 
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
        source  => 'https://support.online',
        flair   => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="support.online">support.online</span> </div>',
        plain   => 'https://support.online',
        entity  => [ { type => 'domain', value => 'support.online' } ],
    },
);

foreach my $href (@domains) {

    my $result  = $extractor->process_html($href->{source});
    is($result->{text}, $href->{plain}, "For $href->{source}, plain text is correct");
    is($result->{flair}, $href->{flair}, "For $href->{source}, flair html is corrent");
    cmp_bag($result->{entities}, $href->{entity}, "For $href->{source}, entities are correct");

}

done_testing();
exit 0;
    

    
