#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';
use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;
use Mojo::JSON qw(encode_json decode_json);
use Scot::App::Flair;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups = ( 'ir', 'test' );

foreach my $k (keys %ENV) {
    next unless $k =~ /scot/;
    print "$k = $ENV{$k}\n";
}

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;

my $col = $env->mongo->collection('Alertgroup');
my $aghash = {
    request => {
        json    => {
            message_id      => '123',
            subject        => "External HREF in Email",
            source         => [ qw(email_examinr) ],
            tag            => [ qw(email href) ],
            groups          => {
                read        => [ qw(wg-scot-ir) ],
                modify      => [ qw(wg-scot-ir) ],
            },
            columns         => [ qw(MAIL_FROM MAIL_TO HREFS SUBJECT) ],
            data            => [
                {
                    # alert 1
                    MAIL_FROM   => "amlegit\@partner.net",
                    MAIL_TO     => "br549\@sandia.gov",
                    HREFS       => q{http://spmiller.org/news/please_read.html},
                    SUBJECT     => "Groundbreaking research!",
                },
                {
                    # alert 2
                    MAIL_FROM   => "scbrb\@aa.edu",
                    MAIL_TO     => "tbruner\@sandia.gov",
                    HREFS       => q{https://www.aa.edu/athletics/schedule},
                    SUBJECT     => "Schedule for next week",
                },
                {
                    # alert 3
                    MAIL_FROM   => "bubba\@bbn.com",
                    MAIL_TO     => "fmilszx\@sandia.gov",
                    HREFS       => "https://youtu.be/JAUoeqvedMo",
                    SUBJECT     => "Can not wait!",
                }
            ],
        },
    },
};

my $obj = $col->api_create($aghash);

my $alertgroup = $col->find_iid(1);
my $update = {
          'type' => 'alertgroup',
          'id' => 1,
          'parsed' => 1,
          'updated' => 1500947054,
          'alerts' => [
                        {
                          'data_with_flair' => {
                                                 'MAIL_FROM' => '<div><span class="entity email" data-entity-type="email" data-entity-value="amlegit@partner.net">amlegit@<span class="entity domain" data-entity-type="domain" data-entity-value="partner.net">partner.net</span></span> </div>',
                                                 'SUBJECT' => '<div>Groundbreaking research! </div>',
                                                 'MAIL_TO' => '<div><span class="entity email" data-entity-type="email" data-entity-value="br549@sandia.gov">br549@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span> </div>',
                                                 'HREFS' => '<div>http://<span class="entity domain" data-entity-type="domain" data-entity-value="spmiller.org">spmiller.org</span>/news/please_read.html </div>'
                                               },
                          'entities' => [
                                          {
                                            'type' => 'domain',
                                            'value' => 'partner.net'
                                          },
                                          {
                                            'type' => 'email',
                                            'value' => 'amlegit@partner.net'
                                          },
                                          {
                                            'type' => 'domain',
                                            'value' => 'sandia.gov'
                                          },
                                          {
                                            'value' => 'br549@sandia.gov',
                                            'type' => 'email'
                                          },
                                          {
                                            'type' => 'domain',
                                            'value' => 'spmiller.org'
                                          }
                                        ],
                          'id' => 1,
                          'parsed' => 1
                        },
                        {
                          'parsed' => 1,
                          'id' => 2,
                          'entities' => [
                                          {
                                            'type' => 'domain',
                                            'value' => 'sandia.gov'
                                          },
                                          {
                                            'value' => 'tbruner@sandia.gov',
                                            'type' => 'email'
                                          },
                                          {
                                            'type' => 'domain',
                                            'value' => 'www.aa.edu'
                                          },
                                          {
                                            'type' => 'domain',
                                            'value' => 'aa.edu'
                                          },
                                          {
                                            'type' => 'email',
                                            'value' => 'scbrb@aa.edu'
                                          }
                                        ],
                          'data_with_flair' => {
                                                 'MAIL_TO' => '<div><span class="entity email" data-entity-type="email" data-entity-value="tbruner@sandia.gov">tbruner@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span> </div>',
                                                 'HREFS' => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="www.aa.edu">www.aa.edu</span>/athletics/schedule </div>',
                                                 'SUBJECT' => '<div>Schedule for next week </div>',
                                                 'MAIL_FROM' => '<div><span class="entity email" data-entity-type="email" data-entity-value="scbrb@aa.edu">scbrb@<span class="entity domain" data-entity-type="domain" data-entity-value="aa.edu">aa.edu</span></span> </div>'
                                               }
                        },
                        {
                          'parsed' => 1,
                          'data_with_flair' => {
                                                 'MAIL_FROM' => '<div><span class="entity email" data-entity-type="email" data-entity-value="bubba@bbn.com">bubba@<span class="entity domain" data-entity-type="domain" data-entity-value="bbn.com">bbn.com</span></span> </div>',
                                                 'SUBJECT' => '<div>Can not wait! </div>',
                                                 'HREFS' => '<div>https://<span class="entity domain" data-entity-type="domain" data-entity-value="youtu.be">youtu.be</span>/JAUoeqvedMo </div>',
                                                 'MAIL_TO' => '<div><span class="entity email" data-entity-type="email" data-entity-value="fmilszx@sandia.gov">fmilszx@<span class="entity domain" data-entity-type="domain" data-entity-value="sandia.gov">sandia.gov</span></span> </div>'
                                               },
                          'id' => 3,
                          'entities' => [
                                          {
                                            'type' => 'domain',
                                            'value' => 'youtu.be'
                                          },
                                          {
                                            'value' => 'sandia.gov',
                                            'type' => 'domain'
                                          },
                                          {
                                            'value' => 'fmilszx@sandia.gov',
                                            'type' => 'email'
                                          },
                                          {
                                            'value' => 'bbn.com',
                                            'type' => 'domain'
                                          },
                                          {
                                            'value' => 'bubba@bbn.com',
                                            'type' => 'email'
                                          }
                                        ]
                        }
                      ]
        };

$col->update_alertgroup_with_bundled_alert($update);

done_testing();
exit 0;

