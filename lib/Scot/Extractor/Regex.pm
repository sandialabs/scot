package Scot::Extractor::Regex;

use strict;
use warnings;
# use re 'debug';
use Data::Dumper;
use Mozilla::PublicSuffix qw(public_suffix);
use Try::Tiny;
use HTML::Element;
use HTML::Entities;
use namespace::autoclean;
use Moose;

my @ss  = (); # see Mastering Regular Expression, 3rd Ed. Chpt.7

has env   => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);


sub BUILD {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $config_ee_regexes = $self->config->{entity_regexes};

    my $meta   = $self->meta;
    $meta->make_mutable;

    # load regexes that are in config file attr "entity_regexes"

    foreach my $href (@{$self->config->{entity_regexes}}) {
        $log->trace("building attr from ",{filter=>\&Dumper, value=>$href});
        my $attrname    = 'regex_'.$href->{type};
        $meta->add_attribute(
            $attrname => (
                is          => 'rw',
                isa         => 'HashRef'
            )
        );
        $self->$attrname({
            type    => $href->{type},
            regex   => $href->{regex},
            order   => $href->{order},
            options => $href->{options},
        });
    }

#### commenting this out because I want user defined flair to come from 
#### an entitytype collection.  Leaving it here in case I change my mind
#### AGAIN.
#    # load from signatures mongo collection
#    my $scol    = $mongo->collection('Signature');
#    my $bcol    = $mongo->collection('Sigbody');
#
#    my $cursor  = $scol->find({ signature_group => 'scot_flair' });
#    while ( my $signature = $cursor->next ) {
#        my $bodycur = $bcol->find({signature_id => $signature->id});
#        $bodycur->sort({revision => -1});
#        my $sigbody     = $bodycur->next;
#        my $attrname    = "regex_".$signature->name;
#        $meta->add_attribute(
#            $attrname   => (
#                is      => 'rw',
#                isa     => 'HashRef'
#            )
#        );
#        $self->$attrname({
#            type    => $signature->type,
#            regex   => $self->build_re($sigbody->body),
#            order   => 100,
#            options => $signature->options,
#        });
#    }

    # finally load from EntityTypes (prefered location)

    $self->load_entitytypes($meta);

}

sub get_nonconflict_attrname {
    my $self    = shift;
    my $meta    = shift;
    my $suffix  = shift;
    my $prefix  = "regex_";
    my $post    = 0;

    my $attrname    = $prefix . $suffix;
    while ( $meta->has_attribute( $attrname ) ) {
        $post       += 1;
        $attrname   = $prefix . $suffix . $post;
    }
    return $attrname;
}

sub load_entitytypes {
    my $self    = shift;
    my $meta    = $self->meta;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $etcol   = $mongo->collection('Entitytype');
    my $etcur   = $etcol->find({});

    $meta->make_mutable;

    while ( my $etype = $etcur->next ) {
        next if ( $etype->status ne "active" );
        my $attrname    = $self->get_nonconflict_attrname($meta,$etype->value);
        $meta->add_attribute(
            $attrname   => (
                is      => 'rw',
                isa     => 'HashRef',
            )
        );
        $self->$attrname({
            type    => $etype->value,
            regex   => $self->build_re($etype->match),
            order   => $etype->order,
            options => $etype->options,
        });
        $log->trace("created $attrname");
    }
    $meta->make_immutable;
}


sub build_re {
    my $self    = shift;
    my $text    = shift;
    my $log     = $self->env->log;
    my $re;

    $log->trace("building re from $text");

    my $quoted  = quotemeta($text);

#    if ( $text =~ /\// ) {
#        my ($pre,$match,$post) = split(/\//,$text);
#        $re  = qr/(?$post)$match/;
#    }
#    else {
        $re = qr/$quoted/i;
#    }

    return $re;
}

sub get_regex {
    my $self    = shift;
    my $rename  = shift;
    my $meta    = $self->meta;
    my $env     = $self->env;
    my $log     = $env->log;
    my $method  = $meta->get_attribute($rename);

    if ( defined $method ) {
        return $self->$rename;
    }

    $log->error("No regex $rename exists!");
    die "Regex $rename not found in ".__PACKAGE__;
}

has all_regexes => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => 'list_regexes',
);

sub list_regexes {
    my $self    = shift;
    my $meta    = $self->meta;
    my @renames = grep { /^regex_/ } $meta->get_attribute_list;
    my @regexes = ();

    foreach my $rename (@renames) {
        my $rehash = $self->get_regex($rename);
        $rehash->{attr} = $rename;
        push @regexes, $rehash;
    }

    @regexes = sort { $a->{order} <=> $b->{order} } @regexes;

    return wantarray ? @regexes : \@regexes;
}

has multi_word_regexes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    required=> 1,
    lazy    => 1,
    builder => 'list_multiword_regexes',
);

sub list_multiword_regexes {
    my $self    = shift;
    my $log     = $self->env->log;
    my @regexes = sort { $a->{order} <=> $b->{order} } grep { 
        defined( $_->{options}->{multiword} ) and
        $_->{options}->{multiword} eq "yes" 
    } @{$self->all_regexes};
    $log->debug("Found ".scalar(@regexes)." regexes");
    return wantarray ? @regexes : \@regexes;
}

has single_word_regexes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    required=> 1,
    lazy    => 1,
    builder => 'list_singleword_regexes',
);

sub list_singleword_regexes {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my @regexes = sort { $a->{order} <=> $b->{order} } grep { 
        (
            defined( $_->{options}->{multiword} ) 
            and
            $_->{options}->{multiword} eq "no" 
        ) 
        or 
        (
            ! defined $_->{options}->{multiword} 
        )
    } @{$self->all_regexes};
    $log->debug("Found ".scalar(@regexes)." regexes");
    return wantarray ? @regexes : \@regexes;
}

=item B<CVE>

The regex will pull out CVE-2017-10032 out of text

=cut

has regex_CVE => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_CVE',
);

sub _build_CVE {
    my $self    = shift;
    my $regex   = qr{
        \b                      # word boundary
        (CVE-(\d{4})-(\d{4,}))  # CVE-YYYY-XXXX...
        \b                      # word boundary
    }xims;
    return {
        regex   => $regex,
        type    => "cve",
        order   => 100,
        options => { multiword => "no" },
    };
}

=item B<cidr>

This regex will detect CIDR blocks of the formate a.b.c.d/e

=cut

has regex_CIDR  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_CIDR',
);

sub _build_CIDR {
    my $self    = shift;
    my $regex   = qr{
        \b                                      # word boundary
        (?<!\.)
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
        regex   => $regex,
        type    => "cidr",
        order   => 1,
        options => { multiword => "yes" },
    };
}

=item B<CLSID>

Microsoft object CLSID

=cut

has regex_CLSID     => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_CLSID',
);

sub _build_CLSID {
    my $self    = shift;
    my $regex   = qr{
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
        regex   => $regex,
        type    => "clsid",
        order   => 100,
        options => { multiword => "no" },
    };
}

=item B<md5>

The regex will pull out md5 out of text

=cut

has regex_MD5 => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_MD5',
);

sub _build_MD5 {
    my $self    = shift;
    my $regex   = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{32})
        \b                      # word boundary
    }xims;
    return {
        regex   => $regex,
        type    => "md5",
        order   => 100,
        options => { multiword => "no" },
    };
}

=item B<sha1>

The regex will pull out sha1

=cut

has regex_SHA1 => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_SHA1',
);

sub _build_SHA1 {
    my $self    = shift;
    my $regex   = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{40})
        \b                      # word boundary
    }xims;
    return {
        regex   => $regex,
        type    => "sha1",
        order   => 100,
        options => { multiword => "no" },
    };
}

=item B<sha256>

The regex will pull out sha1

=cut

has regex_SHA256 => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_SHA256',
);

sub _build_SHA256 {
    my $self    = shift;
    my $regex   = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{64})
        \b                      # word boundary
    }xims;
    return {
        regex   => $regex,
        type    => "sha256",
        order   => 100,
        options => { multiword => "no" },
    };
}

=item B<ipv6>

detect IPv6 addresses

=cut

has regex_IPV6 => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_IPV6',
);

sub _build_IPV6 {
    my $self    = shift;
    my $re      = qr{
    \b
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
        regex => $re,
        type    => "ipv6",
        order   => 11,
        options => { multiword => "yes" },
    };
}

has regex_IPV6_suricata => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_IPV6_suricata',
);
sub _build_IPV6_suricata {
    my $self    = shift;
    my $re      = qr{
    \b
	(?:
	(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}
    )(?=:[0-9]+)
    \b
    };
    return {
        regex => $re,
        type    => "ipv6",
        order   => 9,
        options => { multiword => "yes" },
    };
}

sub _build_IPV6_not {
    my $self    = shift;
    my $ipv4 = "((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))";
    my $hex = "[0-9a-fA-F]{1,4}";

    my @tail = ( ":",
              "(:($hex)?|$ipv4)",
              ":($ipv4|$hex(:$hex)?|)",
              "(:$ipv4|:$hex(:$ipv4|(:$hex){0,2})|:)",
              "((:$hex){0,2}(:$ipv4|(:$hex){1,2})|:)",
              "((:$hex){0,3}(:$ipv4|(:$hex){1,2})|:)",
              "((:$hex){0,4}(:$ipv4|(:$hex){1,2})|:)" );

    my $ipv6_re = $hex;
    $ipv6_re = "$hex:($ipv6_re|$_)" for @tail;
    $ipv6_re = qq/:(:$hex){0,5}((:$hex){1,2}|:$ipv4)|$ipv6_re/;
    $ipv6_re =~ s/\(/(?:/g;
    $ipv6_re = qr/$ipv6_re/;
    return {
        regex => $ipv6_re,
        type    => "ipv6",
        order   => 11,
        options => { multiword => "no" },
    };
}

=item B<DOMAIN>

pretty loose regex to match domain looking strings
SCOT will then grep through the publlic suffix list
to see if it matches before declaring it a domain

=cut

has regex_DOMAIN => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_DOMAIN',
);

sub _build_DOMAIN {
    my $self    = shift;
    my $regex   = qr{
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
#            (xn--)?
            [-a-z0-9]{2,63}
        )
        (\b|\/)                                      # word boundary
    }xims;
    return {
        regex   => $regex,
        type    => 'domain',
        order   => 10,
        options => { multiword => "no" },
    };
}

=item B<ipaddr>

IPv4 regex

=cut

has regex_IPADDR => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_IPADDR',
);

sub _build_IPADDR {
    my $self    = shift;
    my $regex   = qr{
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
        regex   => $regex,
        type    => 'ipaddr',
        order   => 10, # needs to after the cidr match
        options => { multiword => "no" },
    };
}

=item B<email>

the email regex

=cut

has regex_EMAIL => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_EMAIL',
);

sub _build_EMAIL {
    my $self    = shift;
    my $regex   = qr{
        \b
        (
            (?:
                [\=a-z0-9!#$%&'*+/?^_`{|}~-]+             # one or more of these
                (?:\.[\=a-z0-9!#$%&'*+/?^_`{|}~-]+)*      # zero or more of these
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
        regex   => $regex,
        type    => "email",
        order   => 9,
        options => { multiword => "no" },
    };
}

has regex_lbsig => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_LBSIG',
);

sub _build_LBSIG {
    my $self    = shift;
    my $regex   = qr{
        \b
        (yr:[a-z\_]+_s[0-9]+)_[0-9]+
        \b
    }xims;
    return {
        regex   => $regex,
        type    => "lbsig",
        order   => 10,
        options => { multiword => "yes" },
    };
}

has regex_winregistry => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_WINREGISTRY',
);

sub _build_WINREGISTRY {
    my $self    = shift;
    my $regex   = qr{
        \b((hklm|hkcu|hkey)[\\\w]+)\b
    }xims;
    return {
        regex   => $regex,
        type    => "winregistry",
        order   => 10,
        options => { multiword => "no" },
    };
}

has regex_common_file_ext => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_COMMON_FILE_EXT',
);

sub _build_COMMON_FILE_EXT {
    my $self    = shift;
    my $regex   = qr{
        \b
        [0-9a-zA-Z_\-\.]+
        \.
        (cfm|exe|bat|zip|txt|rar|tar|dll|7z|ps1|vbs|js|pdf|msi|hta|mht|doc|docx|xls|xlsx|ppt|pptx|jse|jar|vbe|wsf|wsh|sct|wsc)
        \b
    }xims;
    return {
        regex   => $regex,
        type    => "file",
        order   => 9,
        options => { multiword => "no" },
    };
}

has regex_python_file_ext => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_PYTHON_FILE_EXT',
);

sub _build_PYTHON_FILE_EXT {
    my $self    = shift;
    my $regex   = qr{
        \b
        [0-9a-zA-Z_\-\.]+
        \.
        py
        \b
    }xims;
    return {
        regex   => $regex,
        type    => "file",
        order   => 9,
        options => { multiword => "no" },
    };
}

has regex_appkey => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_APPKEY',
);

sub _build_APPKEY {
    my $self    = shift;
    my $regex   = qr{
        \b
        (
        AppKey=([0-9a-f]){28}
        )
        \b
    }xims;
    return {
        regex   => $regex,
        type    => "appkey",
        order   => 10,
        options => { multiword => "no" },
    };
}

has regex_UUID1 => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_UUID1',
);

sub _build_UUID1 {
    my $self    = shift;
    my $hex     = qr{[0-9a-f]};
    my $regex   = qr{
        \b
        (
        $hex{8}-$hex{4}-11[ef]$hex-[89ab]$hex{3}-$hex{12}
        )
        \b
    }xms;
    return {
        regex   => $regex,
        type    => "uuid1",
        order   => 20,
        options => { multiword => "no" },
    };
}

has regex_angle_bracket_message_id => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_angle_bracket_message_id',
);

sub _build_angle_bracket_message_id {
    my $self    = shift;
    my $regex   = qr{
        (
        (<|&lt;)
        (?:[^\s]*?)
        @
        (?:[^\s]*?)
        (>|&gt;)
        )
    }xms;
    return {
        regex   => $regex,
        type    => "message_id",
        order   => 5,
        options => { multiword => "yes" },
    };
}

has regex_jarm_hash => (
    is          => 'ro',
    isa      => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_jarm_hash',
);

sub _build_jarm_hash {
    my $self    = shift;
    my $regex   = qr{
        \b                      # word boundary
        (?!.*\@\b)([0-9a-fA-F]{62})
        \b                      # word boundary
    }xims;
    return {
        regex   => $regex,
        type    => "jarm_hash",
        order   => 200,
        options => { multiword => "no" },
    };
}

sub find_all_matches {
    my $self    = shift;
    my $word    = shift;
    my $regexes = $self->all_regexes;
    return $self->find_matches($word, $regexes);
}

sub find_singleword_matches {
    my $self    = shift;
    my $word    = shift;
    my $regexes = $self->single_word_regexes;
    return $self->find_matches($word, $regexes);
}

sub find_multiword_matches {
    my $self    = shift;
    my $word    = shift;
    my $regexes = $self->multi_word_regexes;
    return $self->find_matches($word, $regexes);
}

# this sub will iterate throught the regular expressions
# when it finds a match, it short circuits and returns the 
# type of regex and the pre, match, post strings

sub find_matches {
    my $self    = shift;
    my $word    = shift;
    my $rearef  = shift;
    my $log     = $self->env->log;

    foreach my $rehash (@$rearef) {
        my $type    = $rehash->{type};
        my $regex   = $rehash->{regex};
        $log->trace("$word: Try to match a $type");

        if ( $word =~ m/$regex/ ) {

            $log->debug("$word matches");
            
            my $pre     = substr($word, 0, $-[0]);
            my $match   = substr($word, $-[0], $+[0] - $-[0]);
            my $post    = substr($word, $+[0]);

            return {
                type    => $type, 
                pre     => $pre, 
                match   => $match, 
                post    => $post };
        }
        $log->trace("$type match failed on $word");
    }
    return {};
}

1;
