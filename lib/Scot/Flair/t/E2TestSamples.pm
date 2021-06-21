package E2TestSamples;
use HTML::Element;
use Moose;
use warnings;
use strict;

sub create_target_span {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    my $element = HTML::Element->new(
        'span',
        'class' => "entity $type",
        'data-entity-type'  => $type,
        'data-entity-value' => lc($value),
    );
    $element->push_content($value);
    return $element;
}

sub build_flair_error_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'alert 605543 user agent cell',
        source  => 'DirBuster-0.12 (http://www.owasp.org/index.php/Category:OWASP_DirBuster_Project)',
        flair   => [
            'DirBuster-0.12',
            ' (http://',
            $self->create_target_span('www.owasp.org', 'domain'),
            '/',
            $self->create_target_span('index.php', 'file'),
            '/Category:OWASP_DirBuster_Project)',
        ],
        entities => [
            { type => 'domain', value => 'www.owasp.org' },
            { type => 'file', value => 'index.php' },
        ]
    };
    return wantarray ?  @tests : \@tests;
}

sub build_local_tests {
    my $self    = shift;
    my @tests   = ();
    push @tests, {
        name    => 'snumber',
        source  => 'The property number is s944944 and can be found next door.',
        flair   => [
            'The property number is ',
            $self->create_target_span('s944944', 'snumber'),
            ' and can be found next door.',
        ],
        entities => [
            { type => 'snumber', value => 's944944', },
        ],
    };
    push @tests, {
        name    => 'server',
        source  => 'The server as0000snllx is down.',
        flair   => [
            'The server ',
            $self->create_target_span('as0000snllx', 'sandia_server'),
            ' is down.',
        ],
        entities => [
            { type => 'sandia_server', value => 'as0000snllx', },
        ],
    };
    return wantarray ? @tests : \@tests;
}

sub build_domain_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'scot-7397',
        source  => 'https://cbase.som.sunysb.edu/soap/bss.cfm',
        flair   => [
            'https://',
            $self->create_target_span('cbase.som.sunysb.edu', 'domain'),
            '/soap/',
            $self->create_target_span('bss.cfm', 'file'),
        ],
        entities => [
            { type => 'file',   value => 'bss.cfm' },
            { type => 'domain', value => 'cbase.som.sunysb.edu' },
        ]
    };
    push @tests, {
        name    => 'google plain',
        source  => 'www.google.com',
        flair   => [
            $self->create_target_span('www.google.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ]
    };
    push @tests, {
        name    => 'google obsfucated 1',
        source  => 'www(.)google(.)com',
        flair   => [
            $self->create_target_span('www.google.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ]
    };
    push @tests, {
        name    => "googel obsfucated 2",
        source  => 'www[.]google[.]com',
        flair   => [
            $self->create_target_span('www.google.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ]
    };
    push @tests, {
        name    => "googel obsfucated 3",
        source  => 'www{.}google{.}com',
        flair   => [
            $self->create_target_span('www.google.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ]
    };
    push @tests, {
        name    => "googel obsfucated 4",
        source  => 'foo(.)www{.}google[.]com',
        flair   => [
            $self->create_target_span('foo.www.google.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'foo.www.google.com' },
        ]
    };
    push @tests, {
        name    => "googel obsfucated 5",
        source  => 'www.google[.]com',
        flair   => [
            $self->create_target_span('www.google.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'www.google.com' },
        ]
    };
    push @tests, {
        name    => "dotted hex string negative match",
        source  => '8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99',
        flair   => [
           '8a.93.8c.99.8d.61.62.86.97.88.86.91.91.8e.4e.97.8a.99',
        ],
        entities => [
        ]
    };
    push @tests, {
        name    => 'domain with numeric component',
        source  => 'foo.10.com',
        flair   => [
            $self->create_target_span('foo.10.com', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'foo.10.com' },
        ]
    };
    push @tests, {
        name    => 'id tld',
        source  => 'paziapm.co.id',
        flair   => [
            $self->create_target_span('paziapm.co.id', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'paziapm.co.id' },
        ]
    };
    push @tests, {
        name    => 'puny code 1',
        source  => 'foo.xn--p1ai',
        flair   => [
            $self->create_target_span('foo.xn--p1ai', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'foo.xn--p1ai' },
        ]
    };
    push @tests, {
        name    => 'puny code 2',
        source  => 'xn--clapcibic1.xn--p1ai',
        flair   => [
            $self->create_target_span('xn--clapcibic1.xn--p1ai', 'domain'),
        ],
        entities => [
            { type => 'domain', value => 'xn--clapcibic1.xn--p1ai' },
        ]
    };

            
    return wantarray ? @tests : \@tests;
}

sub build_ipv4_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'easy ipaddr',
        source  => '10.10.10.1',
        flair   => [
            $self->create_target_span('10.10.10.1', 'ipaddr')
        ],
        entities => [
            { type => 'ipaddr', value => '10.10.10.1' },
        ],
    };
    push @tests, {
        name    => 'ipaddr with trailing comma',
        source  => '10.10.10.1, fun',
        flair   => [
            $self->create_target_span('10.10.10.1', 'ipaddr'),
            ', fun',
        ],
        entities => [
            { type => 'ipaddr', value => '10.10.10.1' },
        ],
    };
    push @tests, {
        name    => 'ipaddr with trailing period',
        source  => '10.10.10.1. so fun',
        flair   => [
            $self->create_target_span('10.10.10.1', 'ipaddr'),
            '. so fun',
        ],
        entities => [
            { type => 'ipaddr', value => '10.10.10.1' },
        ],
    };
    push @tests, {
        name    => 'ipaddr in middle of text',
        source  => 'This address, 10.10.10.1, appears a lot',
        flair   => [
            'This address, ',
            $self->create_target_span('10.10.10.1', 'ipaddr'),
            ', appears a lot',
        ],
        entities => [
            { type => 'ipaddr', value => '10.10.10.1' },
        ],
    };
    push @tests, {
        name    => 'ipaddrs with various obsfucations',
        source  => '10(.)10(.)10(.)1 20[.]20[.]20[.]2 30{.}30{.}30{.}3 40.40.40(.)4',
        flair   => [
            $self->create_target_span('10.10.10.1', 'ipaddr'),
            ' ',
            $self->create_target_span('20.20.20.2', 'ipaddr'),
            ' ',
            $self->create_target_span('30.30.30.3', 'ipaddr'),
            ' ',
            $self->create_target_span('40.40.40.4', 'ipaddr'),
        ],
        entities => [
            { type => 'ipaddr', value => '10.10.10.1' },
            { type => 'ipaddr', value => '20.20.20.2' },
            { type => 'ipaddr', value => '30.30.30.3' },
            { type => 'ipaddr', value => '40.40.40.4' },
        ],
    };
    push @tests, {
        name    => 'ipv4 with leading ip4:',
        source  => 'ip4:65.38.177.13',
        flair   => [
            'ip4:',
            $self->create_target_span('65.38.177.13', 'ipaddr')
        ],
        entities => [
            { type => 'ipaddr', value => '65.38.177.13' },
        ],
    };

    return wantarray ? @tests : \@tests;
}

sub build_ipv6_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'ipv6 1',
        source  => '1762:0:0:0:0:B03:1:AF18',
        flair   => [
            $self->create_target_span('1762:0:0:0:0:b03:1:af18', 'ipv6')
        ],
        entities => [
            { type => 'ipv6', value => '1762:0:0:0:0:b03:1:af18' },
        ],
    };
    push @tests, {
        name    => 'ipv6 1 a',
        source  => 'foo 1762:0:0:0:0:B03:1:AF18 bar',
        flair   => [
            'foo ',
            $self->create_target_span('1762:0:0:0:0:b03:1:af18', 'ipv6'),
            ' bar',
        ],
        entities => [
            { type => 'ipv6', value => '1762:0:0:0:0:b03:1:af18' },
        ],
    };
    push @tests, {
        name    => 'ipv6 2',
        source  => '1762::B03:1:AF18',
        flair   => [
            $self->create_target_span('1762:0:0:0:0:b03:1:af18', 'ipv6'),
        ],
        entities => [
            { type => 'ipv6', value => '1762:0:0:0:0:b03:1:af18' },
        ],
    };
    push @tests, {
        name    => 'ipv6 2 a',
        source  => 'foo 1762::B03:1:AF18 bar',
        flair   => [
            'foo ',
            $self->create_target_span('1762:0:0:0:0:b03:1:af18', 'ipv6'),
            ' bar',
        ],
        entities => [
            { type => 'ipv6', value => '1762:0:0:0:0:b03:1:af18' },
        ],
    };
    push @tests, {
        name    => 'ipv6 3',
        source  => '2001:41d0:2:9d17::',
        flair   => [
            $self->create_target_span('2001:41d0:2:9d17:0:0:0:0', 'ipv6'),
        ],
        entities => [
            { type => 'ipv6', value => '2001:41d0:2:9d17:0:0:0:0' },
        ],
    };
    push @tests, {
        name    => 'event 14246 IPv6 problem',
        source  => 'by BN6PR27MB2539.namprd13.prod.poutlook.org (2603:10b6:404:129::18)',
        flair   => [
            'by ',
            $self->create_target_span('BN6PR27MB2539.namprd13.prod.poutlook.org', 'domain'),
            ' (',
            $self->create_target_span('2603:10b6:404:129:0:0:0:18', 'ipv6'),
            ')'
        ],
        entities    => [
            { type => 'domain', value => 'bn6pr27mb2539.namprd13.prod.poutlook.org' },
            { type => 'ipv6',   value => '2603:10b6:404:129:0:0:0:18' },
        ],
    };


    return wantarray ? @tests : \@tests;
}

sub create_email_span {
    my $self    = shift;
    my $email   = shift;
    my $type    = shift;

    my @parts = split(/\@/, $email);
    my $user    = $parts[0];
    my $domain  = $parts[1];

    my $email_element = HTML::Element->new(
        'span',
        'class' => "entity email",
        'data-entity-type'  => "email",
        'data-entity-value' => lc($email),
    );

    $email_element->push_content($user);
    $email_element->push_content('@');

    my $domain_element = HTML::Element->new(
        'span',
        'class' => "entity domain",
        'data-entity-type'  => 'domain',
        'data-entity-value' => lc($domain),
    );
    $domain_element->push_content($domain);
    $email_element->push_content($domain_element);
    return $email_element;
}

sub build_email_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'email in text',
        source  => 'The email is tbruner@sandia.gov until tomorrow',
        flair   => [
            'The email is ',
            $self->create_email_span('tbruner@sandia.gov', 'email'),
            ' until tomorrow',
        ],
        entities    => [
            { type => 'email', value => 'tbruner@sandia.gov' },
            { type => 'domain', value => 'sandia.gov' },
        ],
    };
    push @tests, {
        name    => 'email with underscore text',
        source  => 'The email is todd_bruner@sandia.gov until tomorrow',
        flair   => [
            'The email is ',
            $self->create_email_span('todd_bruner@sandia.gov', 'email'),
            ' until tomorrow',
        ],
        entities    => [
            { type => 'email', value => 'todd_bruner@sandia.gov' },
            { type => 'domain', value => 'sandia.gov' },
        ],
    };
    push @tests, {
        name    => 'email with capitalization',
        source  => 'The email is TODD@sandia.gov until tomorrow',
        flair   => [
            'The email is ',
            $self->create_email_span('TODD@sandia.gov', 'email'),
            ' until tomorrow',
        ],
        entities    => [
            { type => 'email', value => 'todd@sandia.gov' },
            { type => 'domain', value => 'sandia.gov' },
        ],
    };
    push @tests, {
        name    => 'email with =',
        source  => 'The email is bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com',
        flair   => [
            'The email is ',
            $self->create_email_span('bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com', 'email'),
        ],
        entities    => [
            { type => 'email', value => 'bounces+182497-1c5d-xxxx=watermelon.edu@email.followmyhealth.com' },
            { type => 'domain', value => 'email.followmyhealth.com' },
        ],
    };


    return wantarray ? @tests : \@tests;
}

sub build_cve_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'lowercase cve',
        source  => 'was it cve-2017-12345 that was found?',
        flair   => [
            'was it ',
            $self->create_target_span('cve-2017-12345', 'cve'),
            ' that was found?',
        ],
        entities    => [
            { type => 'cve', value => 'cve-2017-12345' },
        ],
    };
    push @tests, {
        name    => 'uppercase cve',
        source  => 'was it CVE-2017-12345 that was found?',
        flair   => [
            'was it ',
            $self->create_target_span('CVE-2017-12345', 'cve'),
            ' that was found?',
        ],
        entities    => [
            { type => 'cve', value => 'cve-2017-12345' },
        ],
    };

    return wantarray ? @tests : \@tests;
}

sub build_file_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'simple file',
        source  => 'invoice.pdf.exe',
        flair   => [
            $self->create_target_span('invoice.pdf.exe', 'file'),
        ],
        entities => [
            { type => 'file', value => 'invoice.pdf.exe' },
        ],
    };
    push @tests, {
        name    => 'simple file 2',
        source  => 'haxor.py',
        flair   => [
            $self->create_target_span('haxor.py', 'file'),
        ],
        entities => [
            { type => 'file', value => 'haxor.py' },
        ],
    };
    push @tests, {
        name    => 'simple file 3',
        source  => '/mnt/gfs/cfdocs/bcatt/templates/pgas_rslts.cfm',
        flair   => [
            '/mnt/gfs/cfdocs/bcatt/templates/',
            $self->create_target_span('pgas_rslts.cfm', 'file'),
        ],
        entities => [
            { type => 'file', value => 'pgas_rslts.cfm' },
        ],
    };
    return wantarray ? @tests : \@tests;
}

sub build_id_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'uuid1-1',
        source  => 'd0229d40-1274-11e8-a427-3d01d7fc9aea',
        flair   => [
            $self->create_target_span('d0229d40-1274-11e8-a427-3d01d7fc9aea', 'uuid1'),
        ],
        entities => [
            { type => 'uuid1', value => 'd0229d40-1274-11e8-a427-3d01d7fc9aea' },
        ],
    };
    push @tests, {
        name    => 'uuid1 in text',
        source  => 'The quick d0229d40-1274-11e8-a427-3d01d7fc9aea uuid check',
        flair   => [
            'The quick ',
            $self->create_target_span('d0229d40-1274-11e8-a427-3d01d7fc9aea', 'uuid1'),
            ' uuid check',
        ],
        entities => [
            { type => 'uuid1', value => 'd0229d40-1274-11e8-a427-3d01d7fc9aea' },
        ],
    };
    push @tests, {
        name    => 'Microsoft CLSID',
        source  => '"{F20DA720-C02F-11CE-927B-0800095AE340}": "OLE Package Object"',
        flair   => [
            '"{',
            $self->create_target_span('F20DA720-C02F-11CE-927B-0800095AE340', 'clsid'),
            '}": "OLE Package Object"',
        ],
        entities => [
            { type => 'clsid', value => 'f20da720-c02f-11ce-927b-0800095ae340' },
        ],
    };
    push @tests, {
        name    => 'LaikaBoss signature 1',
        source  => 'yr:misc_google_amp_link_s75_1',
        flair   => [
            $self->create_target_span('yr:misc_google_amp_link_s75_1', 'lbsig'),
        ],
        entities    => [
            { type => 'lbsig', value => 'yr:misc_google_amp_link_s75_1' },
        ],
    };
    push @tests, {
        name    => 'LaikaBoss signature 2',
        source  => 'yr:misc_vbaproj_codepage_foreign_s63_1',
        flair   => [
            $self->create_target_span('yr:misc_vbaproj_codepage_foreign_s63_1', 'lbsig'),
        ],
        entities    => [
            { type => 'lbsig', value => 'yr:misc_vbaproj_codepage_foreign_s63_1' },
        ],
    };
    return wantarray ? @tests : \@tests;
}

sub build_message_id_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'message_id 1',
        source  => '<CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com>',
        flair   => [
            $self->create_target_span('<CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com>', 'message_id'),
        ],
        entities => [
            { type => 'message_id', value => '<caer1s5-huu1mjnuqtqt6ri-i2zayctm_+cjf6mkmogwgjhjpja@mail.gmail.com>' },
        ],
    };
    push @tests, {
        name    => 'message_id 2',
        source  => '&lt;CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com&gt;',
        flair   => [
            $self->create_target_span('<CAEr1S5-HuU1MjnUQtqT6Ri-i2ZaYcTm_+cjf6mkmOgwGJHjPJA@mail.gmail.com>', 'message_id'),
        ],
        entities => [
            { type => 'message_id', value => '<caer1s5-huu1mjnuqtqt6ri-i2zayctm_+cjf6mkmogwgjhjpja@mail.gmail.com>' },
        ],
    };


    return wantarray ? @tests : \@tests;
}

sub build_cidr_tests {
    my $self    = shift;
    my @tests   = ();

    push @tests, {
        name    => 'cidr 1',
        source  => '10.1.1.0/30',
        flair   => [
            $self->create_target_span('10.1.1.0/30', 'cidr'),
        ],
        entities => [
            { type => 'cidr', value => '10.1.1.0/30' },
        ],
    };
    push @tests, {
        name    => 'cidr 2',
        source  => '10.1.1(.)0/30',
        flair   => [
            $self->create_target_span('10.1.1.0/30', 'cidr'),
        ],
        entities => [
            { type => 'cidr', value => '10.1.1.0/30' },
        ],
    };
    return wantarray ? @tests : \@tests;
}
1;

