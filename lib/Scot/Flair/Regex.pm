package Scot::Flair::Regex;

=head1

Build the set of Regular expressions that the Flair Engine will use

=cut

use strict;
use warnings;
use utf8;
use lib '../../../lib';

use namespace::autoclean;
use Data::Dumper;
use Scot::Flair::Io;
use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
);

has scotio  => (
    is          => 'ro',
    isa         => 'Scot::Flair::Io',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_io',
);

sub _build_scot_io {
    return Scot::Flair::Io->new({env => shift->env});
}

sub all {
    my $self    = shift;
    my @all     = ();

    my @sw = @{$self->single_word_regexes};
    my @mw = @{$self->multi_word_regexes};

    push @all, @mw, @sw;

    return wantarray ? @all : \@all;
}

has single_word_regexes => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    lazy        => 1,
    builder     => '_build_single_word_regexes',
    handles     => {
        add_sw_regex => 'push'
    },
);

sub _build_single_word_regexes {
    my $self    = shift;
    my $io      = $self->scotio;
    my @raw_regex_data  = $io->get_single_word_regexes;
    my @regexes = ();

    push @raw_regex_data, $self->get_built_in_single_word_regexes;
    push @raw_regex_data, $self->get_local_regexes('single');
    push @regexes, $self->build_entitytype_regexes('single');

    foreach my $raw_regex_href (@raw_regex_data) {
        push @regexes, {
            type    => $raw_regex_href->{type},
            regex   => $self->build_re($raw_regex_href->{regex}),
            order   => $raw_regex_href->{order},
            options => $raw_regex_href->{options},
        };
    }
    # sort numerically increasing
    my @sorted = sort { $a->{order} <=> $b->{order} } @regexes;
    return \@sorted;
}

has multi_word_regexes => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    lazy        => 1,
    builder     => '_build_multi_word_regexes',
    handles     => {
        add_mw_regex => 'push'
    },
);

sub _build_multi_word_regexes {
    my $self    = shift;
    my $io      = $self->scotio;

    my @raw_data    = $io->get_multi_word_regexes;
    my @regexes     = ();

    push @raw_data, $self->get_built_in_multi_word_regexes;
    push @raw_data, $self->get_local_regexes('multi');

    foreach my $raw (@raw_data) {
        push @regexes, {
            type    => $raw->{type},
            regex   => $self->build_re($raw->{regex}),
            order   => $raw->{order},
            options => $raw->{options},
        };
    }
    my @etype_data = $self->build_entitytype_regexes('multi');
    push @regexes, @etype_data;
    my @sorted = sort { $a->{order} <=> $b->{order} } @regexes;
    return \@sorted;
}

sub build_entitytype_regexes {
    my $self    = shift;
    my $type    = shift; # single | multi
    my @raw     = $self->get_entitytypes($type);
    my %matches = ();
    # note: last of type overwrites order and options if they differ
    # may be fine or may cause bug
    foreach my $href (@raw) {
        my $type    = $href->{type};
        push @{$matches{$type}{regex}}, quotemeta($href->{regex});
        $matches{$type}{order}   = $href->{order};
        $matches{$type}{options} = $href->{options};
    }
    my @regexes = ();
    foreach my $key (keys %matches) {
        my $pattern = join('|', @{$matches{$key}{regex}});
        my $order   = $self->calculate_order(
            $matches{$key}{order}, 
            scalar(@{$matches{$key}{regex}})
        );
        push @regexes, {
            type    => "$key",
            regex   => qr/($pattern)/,
            order   => $order,
            options => $matches{$key}{options},
        };
    }
    return wantarray ? @regexes : \@regexes;
}

sub calculate_order {
    my $self    = shift;
    my $base    = shift;
    my $num_of_regex = shift;

    return $base - $num_of_regex;
}


sub get_local_regexes {
    my $self    = shift;
    my $type    = shift;
    my $tvalue  = ($type eq "single") ? "no" : "yes";

    my $env             = $self->env;
    my $local_regexes   = $env->get_env_attr('local_regexes');
    my @re              = ();

    return wantarray ? @re : \@re if (! defined $local_regexes);


    foreach my $raw (@$local_regexes) {
        $self->env->log->debug({filter => \&Dumper, value => $raw}) if ($raw->{type} eq 'snumber');
        if ( $raw->{options}->{multiword} eq $tvalue ) {
            my $rre = $raw->{regex};
            push @re, {
                type    => $raw->{type},
                regex   => qr{$rre}xims,
                order   => $raw->{order},
                options => $raw->{options},
            };
        }
    }
    return wantarray ? @re : \@re;
}

sub get_entitytypes {
    my $self    = shift;
    my $type    = shift;
    my $io      = $self->scotio;
    my $log     = $self->env->log;
    my $yn      = ($type eq "multi") ? "yes" : "no";
    my $query   = { options => {multiword => $yn }};
    $log->trace("querying for ",{filter=>\&Dumper, value => $query});
    my @raw     = $io->get_entity_types($query);
    $log->warn("Adding ".scalar(@raw)." regexes to $type");
    return wantarray ? @raw : \@raw;
}

sub build_re {
    my $self    = shift;
    my $text    = shift;
    if ( ref($text) eq "Regexp" ) {
        return $text;
    }
    if ( ref($text) eq "MCONFIG::Regexp" ) {
        print "WEIRD!\n"; 
    }
    if ( ! defined $text ) {
        $self->env->log->warn("asked to build a re from uninitialized string!");
        return;
    }
    my $quoted  = quotemeta($text);
    my $re      = qr/$quoted/xims;
    return $re;
}

sub get_built_in_single_word_regexes {
    my $self    = shift;
    my @re      = ();

    my @re_builder_functions = (qw(
        regex_email
        regex_domain
        regex_cve
        regex_CLSID
        regex_md5
        regex_sha1
        regex_sha256
        regex_ipv4
        regex_winregistry
        regex_common_file_extensions
        regex_appkey
        regex_uuid1
        regex_jarm_hash
        regex_cidr
        regex_ipv6
        regex_lbsig
        regex_angle_bracket_message_id
    ));

    foreach my $function (@re_builder_functions) {
        push @re, $self->$function;
    }

    return wantarray ? @re : \@re;
}

sub get_built_in_multi_word_regexes {
    my $self    = shift;
    my @re      = ();

    my @re_builder_functions = (qw(
    ));

    foreach my $function (@re_builder_functions) {
        push @re, $self->$function;
    }

    return wantarray ? @re : \@re;
}

sub regex_cve {
    my $self    = shift;
    my $type    = 'cve';
    my $order   = 100;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                          # word boundary
        (CVE-(\d{4})-(\d{4,}))      # CVE-YYYY-XXXX....
        \b                          # word boundary
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_cidr {
    my $self    = shift;
    my $type    = 'cidr';
    my $order   = 1;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                                      # word boundary
        (?<!\.)                                 # neg look ahead?
        (
            # first 3 octets with optional [.],{.},(.) obsfucation
            (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\(*\[*\{*\.\)*\]*\}*){3}   
            # last octet
            (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
            (/([0-9]|[1-2][0-9]|3[0-2]))   # the /32
        )
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_CLSID {
    my $self    = shift;
    my $type    = 'clsid';
    my $order   = 100;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                                      # word boundary
        (
        [a-fA-F0-9]{8}
        \-
        [a-fA-F0-9]{4}
        \-
        [a-fA-F0-9]{4}
        \-
        [a-fA-F0-9]{4}
        \-
        [a-fA-F0-9]{12}
        )
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_md5 {
    my $self    = shift;
    my $type    = 'md5';
    my $order   = 100;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{32})
        \b                      # word boundary
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}


sub regex_sha1 {
    my $self    = shift;
    my $type    = 'sha1';
    my $order   = 100;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{40})
        \b                      # word boundary
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_sha256 {
    my $self    = shift;
    my $type    = 'sha256';
    my $order   = 100;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{64})
        \b                      # word boundary
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_ipv6 {
    my $self    = shift;
    my $type    = 'ipv6';
    my $order   = 11;
    my $options = { multiword => 'no' };
    my $re      = qr{
    \b                      # word boundary
    # first look for a suricata/snort format (ip:port)
    (?:
        # look for aaaa:bbbb:cccc:dddd:eeee:ffff:gggg:hhhh
        (?:
            (?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}
        )
        # look for but dont capture a trailing :\d+
        (?=:[0-9]+)
    )
    # next try the rest of the crazy that is ipv6
    # thanks to autors of
    # https://learning.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch08s17.html
	|(?:
        # Mixed
        (?:
            # Non-compressed
            (?:[A-F0-9]{1,4}:){6}
            # Compressed with at most 6 colons
            |(?=(?:[A-F0-9]{0,4}:){0,6}
                (?:[0-9]{1,3}\.){3}[0-9]{1,3}  # and 4 bytes
                (?![:.\w])
            )
            # and at most 1 double colon
            (([0-9A-F]{1,4}:){0,5}|:)((:[0-9A-F]{1,4}){1,5}:|:)
            # Compressed with 7 colons and 5 numbers
            |::(?:[A-F0-9]{1,4}:){5}
	    )
        # 255.255.255.
        (?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}
        # 255
        (?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])

        |# Standard
        (?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}
        |# Compressed with at most 7 colons
        (?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}
            (?![:.\w])
        )  # and anchored
        # and at most 1 double colon
        (([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)
        # Compressed with 8 colons
        |(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7}
	) (?![:.\w]) # neg lookahead to "anchor"
    }xmis;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_ipv6_suricata {
    my $self    = shift;
    my $type    = 'ipv6';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                      # word boundary
        (?:
            (?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}
        )(?=:[0-9]+)
        \b
    }xmis;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_ipv4 {
    my $self    = shift;
    my $type    = 'ipaddr';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                                      # word boundary
        (?<!\.)
        (
            # first 3 octets with optional [.],{.},(.) obsfucation
            (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\(*\[*\{*\.\)*\]*\}*){3}   
            # last octet
            (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
        )
        (?!\.[0-9a-zA-Z])\b
        \b                                      # word boundary
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_email {
    my $self    = shift;
    my $type    = 'email';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                                      # word boundary
        (
            (?:
                # one or more of these
                [\=a-z0-9!#$%&'*+/?^_`{|}~-]+
                # zero or more of these
                (?:\.[\=a-z0-9!#$%&'*+/?^_`{|}~-]+)*
            )
            @
            (?:
                (?!\d+\.\d+)
                (?=.{4,255})
                (?:
                    (?:[a-zA-Z0-9-]{1,63}(?<!-)\(*\[*\{*\.\}*\]*\)*)+
                    [a-zA-Z0-9-]{2,63}
                )
            )
        )
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_lbsig {
    my $self    = shift;
    my $type    = 'lbsig';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                                      # word boundary
        (yr:[a-z\_]+_s[0-9]+)_[0-9]+
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_winregistry {
    my $self    = shift;
    my $type    = 'winregistry';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b                                      # word boundary
        (
            (hklm|hkcu|hkey)[\\\w]+
        )
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_common_file_extensions {
    my $self    = shift;
    my $type    = 'file';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b
        [0-9a-zA-Z_\-\.]+
        \.
        (
            cfm|
            exe|
            bat|
            zip|
            txt|
            rar|
            tar|
            dll|
            7z|
            ps1|
            vbs|
            js|
            pdf|
            msi|
            hta|
            html|
            mht|
            doc|docx|
            xls|xlsx|
            ppt|pptx|
            jse|jar|
            vbe|
            wsf|
            wsh|
            sct|
            tgz|
            py|
            rb|
            php|
            wsc
        )
        \b
    }xims;                         
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_appkey {
    my $self    = shift;
    my $type    = 'appkey';
    my $order   = 10;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b
        (
        AppKey=([0-9a-f]){28}
        )
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}
    
sub regex_uuid1 {
    my $self    = shift;
    my $type    = 'uuid1';
    my $order   = 20;
    my $options = { multiword => 'no' };
    my $hex     = qr{[0-9a-f]};
    my $re      = qr{
        \b
        (
        $hex{8}-$hex{4}-11[ef]$hex-[89ab]$hex{3}-$hex{12}
        )
        \b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_angle_bracket_message_id {
    my $self    = shift;
    my $type    = 'message_id';
    my $order   = 9;
    my $options = { multiword => 'no' };
    my $re      = qr{
        (
            (<|&lt;)            # starts with <
            (?:[^\s]*?)         # has some non blank chars
            @                   # followed by an @
            (?:[^\s]*?)         # followed by more not blank chars
            (>|&gt;)            # ends with >
        )
    }xmis;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}
    
sub regex_jarm_hash {
    my $self    = shift;
    my $type    = 'jarm_hash';
    my $order   = 200;
    my $options = { multiword => 'no' };
    my $re      = qr{
        \b
        (?!.*\@\b)
        ([0-9a-fA-F]{62})
        \b
    };
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_domain {
    my $self    = shift;
    my $type    = 'domain';
    my $order   = 20;
    my $options = { multiword => 'no' };
    my $re      = qr{
        (\b|http[s]*//:)                        # word boundary
        (
            (?=[a-z0-9-]{1,63}
            [\(\{\[]*\.[\]\}\)]*)               # optional obsfucation
            (xn--)?
            [a-z0-9]+
            (-[a-z0-9]+)*
            [\(\{\[]*\.[\]\}\)]*                # optional obsfucation
        )+
        (
            [-a-z0-9]{2,63}
        )
        (\b|\/)                                      # word boundary
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}



1;
