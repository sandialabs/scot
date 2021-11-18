package Scot::Flair3::CoreRegex;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

has regex_set   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    clearer     => 'reload',
    builder     => '_build_regex_set',
);

# consider replacing by looping over meta->get_method_list

sub _build_regex_set ($self) {
    my @set = ();
    push @set, $self->regex_cve;
    push @set, $self->regex_cidr;
    push @set, $self->regex_CLSID;
    push @set, $self->regex_md5;
    push @set, $self->regex_sha1;
    push @set, $self->regex_sha256;
    push @set, $self->regex_ipv6;
    push @set, $self->regex_ipv6_suricata;
    push @set, $self->regex_ipv4;
    push @set, $self->regex_email;
    push @set, $self->regex_lbsig;
    push @set, $self->regex_winregistry;
    push @set, $self->regex_common_file_extensions;
    push @set, $self->regex_appkey;
    push @set, $self->regex_uuid1;
    push @set, $self->regex_angle_bracket_message_id;
    push @set, $self->regex_jarm_hash;
    push @set, $self->regex_domain;
    push @set, $self->regex_snumber;
    my @sort = sort { $a->{order} <=> $b->{order} } @set;
    return wantarray ? @sort : \@sort;
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
    my $order   = 50;
    my $options = { multiword => 'no' };
    my $re  = qr{
        \b(
            [0-9a-zA-Z_\-\.]+
            \.
            (
                7z|arg|deb|pkg|rar|rpm|tar|tgz|gz|z|zip|                  # compressed
                aif|mid|midi|mp3|ogg|wav|wma|                             # audio
                bin|dmg|iso|exe|bat|                                      # executables
                csv|dat|log|mdb|sql|xml|                                  # db/data
                eml|ost|oft|pst|vcf|                                      # email
                apk|bat|bin|cgi|exe|jar|                             # executable
                fnt|fon|otf|ttf|                                          # fonts
                ai|bmp|gif|ico|jpeg|jpg|ps|png|psd|svg|tif|tiff|          # images
                asp|aspx|cer|cfm|css|htm|html|js|jsp|part|php|rss|xhtml|  # web serving
                key|odp|pps|ppt|pptx|                                     # presentation
                c|class|cpp|h|vb|swift|py|rb|                             # source code
                ods|xls|xlsm|xlsx|                                        #spreadsheats
                cab|cfg|cpl|dll|ini|lnk|msi|sys|                          # misc sys files
                3g2|3gp|avi|flv|h264|m4v|mkv|mov|mp4|mpg|mpeg|vob|wmv|   # video
                doc|docx|odt|pdf|rtf|tex|txt|wpd|                        # word processing
                jse|jar|
                ipt|
                hta|
                mht|
                ps1|
                sct|
                scr|
                vbe|vbs|
                wsf|wsh|wsc
            )
        )\b
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
            (<|&lt;)            # starts with < or &lt;
            (?:[^\s]*?)         # has some non blank chars
            @                   # followed by an @
            (?:[^\s]*?)         # followed by more not blank chars
            (>|&gt;)            # ends with > or &gt;
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
        \b(
            (
                (?= [a-z0-9-]{1,63} [\(\{\[]* \. [\]\}\)]*)
                (xn--)?
                [a-z0-9]+
                (-[a-z0-9]+)*
                [\(\{\[]*
                \.
                [\]\}\)]*
            )+
            (
                [a-z0-9-]{2,63}
            )
            (?<=[a-z])  # prevent foo.12 from being a match
        )\b
    }xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}

sub regex_snumber {
    my $self    = shift;
    my $type    = 'snumber';
    my $order   = 500;
    my $options = { multiword => 'no' };
    my $re      = qr{\b([sS][0-9]{6,7})\b}xims;
    return {
        regex => $re, type => $type, order => $order, options => $options,
    };
}


__PACKAGE__->meta->make_immutable;
1;
