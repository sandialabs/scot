package Scot::Flair::Extractor;

use strict;
use warnings;
use utf8;
use lib '../../../lib';

use Data::Dumper;
use Try::Tiny;
use namespace::autoclean;
use Scot::Flair::Regex;
use Domain::PublicSuffix;
use HTML::Entities;
use HTML::Element;
use HTML::TreeBuilder;
use HTML::FormatText;
use Net::IPv6Addr;
use Carp qw(confess);
use Moose;

my @ss = (); # see "mastering regular expressions", 3rd Ed. Chpt. 7

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has public_suffix => (
    is          => 'ro',
    isa         => 'Domain::PublicSuffix',
    required    => 1,
    lazy        => 1,
    builder     => '_build_public_suffix',
);

sub _build_public_suffix {
    my $self    = shift;
    my $file    = $self->env->mozilla_public_suffix_file;
    return Domain::PublicSuffix->new({
        data_file   => $file
    });
}

has regexes => (
    is          => 'ro',
    isa         => 'Scot::Flair::Regex',
    required    => 1,
    lazy        => 1,
    builder     => '_build_regexes',
);

sub _build_regexes {
    my $self    = shift;
    my $reobj   = Scot::Flair::Regex->new(env=>$self->env);
    return $reobj;
}

#
# Given an String of data
# find all entities within it
# and return:
# {
#   entities => [ { type => type1, value => entity1 }, ... ],
#   flair    => "<div>flaired version of of string</div>",
#   plain   => "plain text version of string",
# }

has max_level => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

sub extract_entities {
    my $self    = shift;
    my $input   = shift;

    # populate and return this
    my %edb = (
        entities => [],
        flair    => '',
        text     => '',
        cache    => {}, # store data to speed things up like previously encountered false +
    );

    my $clean = $self->clean_input($input);

    my @new = $self->parse(\%edb, $clean);

    $edb{flair} = $self->build_html(@new);
    $edb{text}  = $clean;   # gigo

    return wantarray ? %edb : \%edb;
}

sub get_whitespace_in_text {
    my $self    = shift;
    my $text    = shift;
    my @white   = ();
    my $wsre    = qr/\s|<br>|<br \/>/;
    foreach my $w ($text =~ m/$wsre/g) {
        push @white, $w;
    }
    $self->env->log->debug("found ".scalar(@white)." whitespace characters");
    return wantarray ? @white : \@white;
}

sub split_large_text {
    my $self    = shift;
    my $text    = shift;
    my $limit   = 500;
    my $size    = length($text);
    my @parts   = ();
    my $log     = $self->env->log;

    if ( $size < $limit ) {
        $log->debug("Text under limit");
        push @parts, $text;
        return wantarray ? @parts : \@parts;
    }

    my $splitre = qr/\s|<br>|<br \/>/;

    my @words   = split(/$splitre/,$text);
    my @white   = $self->get_whitespace_in_text($text);
    my $ws_count    = scalar(@white);
    my $part    = '';

    my $word_count  = scalar(@words);
    my $char_count  = 0; 

    $log->debug("Word count = $word_count");
    $log->debug("WS   count = $ws_count");

    foreach my $word (@words) {
        my $word_len    = length($word);
        my $ws          = shift @white;
        $char_count     += $word_len;
        $char_count++ if (defined $ws);

        if ( $char_count > $limit ) {
            push @parts, $part;
            $part       = '';
            $char_count = 0;
        }
        $part .= $word;
        $part .= $ws if (defined $ws);
    }
    push @parts, $part;

    $log->debug("Created ".scalar(@parts). " parts");

    return wantarray ? @parts : \@parts;
}

sub parse {
    my $self    = shift;
    my $tracker = shift;
    my $edb     = shift;
    my $text    = shift;
    my $level   = shift // 1;
    my $log     = $self->env->log;
    my @new     = ();

    my @textparts   = $self->split_large_text($text);
    my $partcount   = scalar(@textparts);

    # sometimes a continuous string can be larger than the char limit 
    if ( length($textparts[0]) == 0 ) {
        shift @textparts;
    }
    my $i = 1;
    foreach my $part (@textparts) {
        push @new, $self->recursive_parse($tracker."{p$i/$partcount}", $edb, $part, $level);
        $i++;
    }
    return wantarray ? @new : \@new;
}

sub recursive_parse {
    my $self    = shift;
    my $tracker = shift;
    my $edb     = shift;
    my $text    = shift;
    my $level   = shift // 1;
    my $log     = $self->env->log;
    my @new     = ();

    $log->debug($tracker." - "x$level." begin parse of ".length($text)." characters");

    if ( $text eq '' ) {
        $log->trace($tracker." - "x$level. 'null text');
        return;
    }

    $log->trace($tracker." - "x$level." Text block under size threshold");
    $log->trace($tracker." - "x$level." PARSING = $text");

    if ( $self->max_level < $level ) {
        $self->max_level($level);
    }

    my @all_re          = $self->regexes->all;
    my $total_re        = scalar(@all_re);
    my $re_index        = 0;

    REGEX:
    foreach my $re_href (@all_re) {
        if ( defined $edb->{core} ) {
            $log->trace($tracker." - "x$level." Limited to core REs only");
            next REGEX if ! defined $re_href->{core};
        }
        $re_index++;
        my $re      = $re_href->{regex};
        my $type    = $re_href->{type};

        my ($pre, $flair, $post) = 
            $self->find_flairable($text, $re, $type, $edb, $level, $tracker);

        if ( ! defined $flair ) {
            $log->trace($tracker." - "x$level."Did not match $type ($re_index of $total_re)");
            next REGEX;
        }

        $log->trace($tracker." - "x$level."Found Flairable of type $type. ($re_index of $total_re)");

        # search the pre match text for flair
        $log->debug($tracker." - "x$level."$type flair found, recursing pre match");
        push @new, $self->recursive_parse($tracker,$edb, $pre, $level+1);
        # add the flair
        push @new, $flair;
        # search the post match text for flair
        $log->debug($tracker." - "x$level."flair found, recursing post match");
        push @new, $self->recursive_parse($tracker,$edb, $post, $level+1);

        last REGEX;
    }

    if ( scalar(@new) < 1 ) {
        $log->trace($tracker." - "x$level."No Flairables in Text, pushing text onto stack");
        push @new, $text;
    }
    $log->debug($tracker." - "x$level."parsing complete");
    return wantarray ? @new : \@new;
}

sub find_flairable {
    my $self    = shift;
    my $text    = shift;
    my $re      = shift;
    my $type    = shift;
    my $edb     = shift;
    my $level   = shift;
    my $tracker = shift;
    my $log     = $self->env->log;

    my $PRE     = ''; # hold text before match
    my $attempt = 0;

    MATCH:
    while ( $text =~ m/$re/g ) {
        $attempt++;
        $log->trace($tracker." - "x$level."Attempt $attempt to match type $type");

        my $pre     = substr($text, 0, $-[0]);
        my $match   = substr($text, $-[0], $+[0] - $-[0]);
        my $post    = substr($text, $+[0]); # $'

        if ( defined $match ) {
            $log->trace($tracker." - "x$level."Potentential $type Match $match");
        }

        my $flairable = $self->post_match_actions($match, $type, $edb, $level);

        if (defined $flairable) {
            # we found a positive match
            $log->trace($tracker." - "x$level."Found Flairable ".$flairable->as_HTML." in $attempt tries");
            $log->trace($tracker." - "x$level."PRE   = ".$PRE.$pre);
            $log->trace($tracker." - "x$level."MATCH = ".$match);
            $log->trace($tracker." - "x$level."POST  = ".$post);
            return $PRE.$pre, $flairable, $post;
        }
        else {  
            # we have a false positive
            $PRE .= $pre . $match; # essentially $`
            $log->trace($tracker." - "x$level."False Positive match, PRE = $PRE");
            $log->trace($tracker." - "x$level."Continuing to match against $post");
            next MATCH;
        }
    }

    # when we reach here, we have exhausted all attempts to match the $re against $text
    # or didn't find any matches in the first place
    $log->trace("Failed to find $type flairable in $attempt passes");
    return undef, undef, undef;
}


sub attempt_match {
    my $self    = shift;
    my $text    = shift;
    my $re      = shift;
    my $type    = shift;
    my $level   = shift;
    my $log     = $self->env->log;

    if ( $text =~ m/$re/ ) {
        my $pre     = substr($text, 0, $-[0]);
        my $match   = substr($text, $-[0], $+[0] - $-[0]);
        my $post    = substr($text, $+[0]);

        $log->debug(" - "x$level,"Type  = $type");
        $log->debug(" - "x$level,"PRE   = $pre");
        $log->debug(" - "x$level,"MATCH = $match");
        $log->debug(" - "x$level,"POST  = $post");

        return $pre, $match, $post;
    }
    # $log->debug($level,"...no match");
    return undef, undef, undef;
}

sub build_html {
    my $self    = shift;
    my @new     = @_;
    my $text    = '';

    my @elements = map { (ref($_)) ? $_->as_HTML : $_ } @new;
    return join('',@elements);
}

sub clean_input {
    my $self    = shift;
    my $input   = shift;
    my $clean   = (utf8::is_utf8($input)) ?
                    Encode::encode_utf8($input) :
                    $input;
    # other data clean here as necessary
    return $clean;
}

sub post_match_actions {
    my $self    = shift;
    my $match   = shift;
    my $type    = shift;
    my $edb     = shift;
    my $level   = shift;

    if ( $type eq "cidr" ) {
        return $self->cidr_action($match, $edb);
    }
    if ( $type eq "domain" ) {
        return $self->domain_action($match, $edb, $level);
    }
    if ( $type eq "ipaddr" ) {
        return $self->ipaddr_action($match, $edb);
    }
    if ( $type eq "ipv6" ) {
        return $self->ipv6_action($match, $edb);
    }
    if ( $type eq "email" ) {
        return $self->email_action($match, $edb);
    }
    if ( $type eq "message_id" ) {
        return $self->message_id_action($match, $edb);
    }
    my $span = $self->create_span($match, $type);
    $self->add_entity($edb, $match, $type);
    return $span;
}

sub create_span {
    my $self    = shift;
    my $match   = shift;
    my $type    = shift;
    my $element = HTML::Element->new(
        'span',
        'class' => "entity $type",
        'data-entity-type'  => $type,
        'data-entity-value' => lc($match),
    );
    $element->push_content($match);
    return $element;
}

sub add_entity {
    my $self    = shift;
    my $edb     = shift;
    my $match   = shift;
    my $type    = shift;

    if ( ! defined $match ) {
        confess();
        die;
    }

    # can have duplicate entities
    #push @{ $edb->{entities} } , {
    #    type    => $type,
    #    value   => lc($match),
    #};
    # no duplication
    $edb->{entities}->{$type}->{lc($match)}++;
}

sub deobsfucate_ipdomain {
    my $self    = shift;
    my $text    = shift;
    my @parts   = split(/[\[\(\{]*\.[\]\)\}]*/, $text);
    my $clear   = join('.',@parts);
    return $clear;
}

sub message_id_action {
    my $self    = shift;
    my $match   = shift;
    my $edb     = shift;

    if ( $match =~ m/^<.*>$/ ) {
        return $self->create_span($match, 'message_id');
    }

    $match =~ s/^&lt;/</;
    $match =~ s/&gt;$/>/;

    return $self->create_span($match, 'message_id');
}


sub cidr_action {
    my $self    = shift;
    my $match   = shift;
    my $edb     = shift;

    my $cidr = $self->deobsfucate_ipdomain($match);
    $self->add_entity($edb, $cidr, 'cidr');
    return $self->create_span($cidr, 'cidr');
}

sub email_action {
    my $self    = shift;
    my $email   = shift;
    my $edb     = shift;
    my $log     = $self->env->log;

    $log->trace("EMAIL ACTION on $email");

    my ( $user, $domain ) = split(/\@/, $email);

    $log->trace("user = $user, domain =$domain");

    $domain = $self->deobsfucate_ipdomain($domain);
    my $domain_span = $self->create_span($domain, "domain");
    $self->add_entity($edb, $domain, 'domain');

    my $new_email = lc($user . '@' . $domain);
    my $email_span = HTML::Element->new(
        'span',
        'class' => 'entity email',
        'data-entity-type' => 'email',
        'data-entity-value' => $new_email,
    );
    $email_span->push_content($user, '@', $domain_span);
    $self->add_entity($edb, $new_email, "email"); 
    return $email_span;
}

sub ipaddr_action {
    my $self    = shift;
    my $ipaddr  = shift;
    my $edb     = shift;

    my $clean   = $self->deobsfucate_ipdomain($ipaddr);
    $self->add_entity($edb, $clean, "ipaddr");
    return $self->create_span($clean, "ipaddr");
}

sub ipv6_action {
    my $self    = shift;
    my $addr    = shift;
    my $edb     = shift;
    my $log     = $self->env->log;

    my $ipobj   = try {
        Net::IPv6Addr->new($addr);
    }
    catch {
        $log->warn("unable to parse ipv6");
        return undef; # sets ipobj to undef
    };

    return undef unless $ipobj;
    my $preferred = $ipobj->to_string_preferred();

    $self->add_entity($edb, $preferred, "ipv6");
    return $self->create_span($preferred, "ipv6");
}

sub domain_action {
    my $self    = shift;
    my $domain  = shift;
    my $edb     = shift;
    my $level   = shift;
    my $log     = $self->env->log;
    my $pds     = $self->public_suffix;

    $domain = $self->deobsfucate_ipdomain($domain);

    $log->trace(" - "x$level. "validating potential domain: $domain");

    # if we have seen this domain before as a false positive, short circuit
    if ( defined $edb->{cache}->{domain_fp}->{$domain} ) {
        return undef;
    }

    return try {
        my $root = $self->get_root_domain($domain);
        if ( ! defined $root ) {
            $log->debug(" - "x$level. "($domain) Error Getting root domain: ".$pds->error);
            $edb->{cache}->{domain_fp}->{$domain}++;
            return undef;
        }
        # special case of zip tld
        if ( $domain =~ m/.*\.zip$/ ) {
            $log->debug(" - "x$level."($domain) zip, although valid tld, assumed to be file extension, since it is more common");
            return undef;
        }
        $self->add_entity($edb, $domain, "domain");
        return $self->create_span($domain, "domain");
    }
    catch {
        $log->debug(" - "x$level. "($domain) Error matching root domain: $_");
        $edb->{cache}->{domain_fp}->{$domain}++;
        return undef;
    };
}

sub get_root_domain {
    my $self    = shift;
    my $domain  = shift;
    my $pds     = $self->public_suffix;

    my $root    = $pds->get_root_domain($domain);
    my $error   = $pds->error() // '';

    if ( $error eq "Domain not valid" ) {

        $root = $pds->get_root_domain("x.".$domain);
        $error= $pds->error();

        if ( ! defined $root ) {
            $self->env->log->error("Root Domain Error: $error");
            return undef;
        }
    }
    return $root;
}

sub user_defined_entity_element {
    my $self    = shift;
    my $child   = shift;
    my $edb     = shift;
    my $log     = $self->env->log;

    my $tag = $child->tag;
    return undef if ($tag ne "span");
    
    my $class   = $child->attr('class') // '';
    if ( ! $self->external_defined_entity_class($class) ) {
        return undef;
    }
    my $type  = $child->attr('data-entity-type');
    my $value = $child->attr('data-entity-value');

    if ( ! defined $type or ! defined $value ) {
        $log->error("User Def misidentitied, skipping: ".$child->as_HTML);
        return undef;
    }

    $self->add_entity($edb, $value, $type);
    $child->attr('class', "entity $class");
    return 1;
}

sub external_defined_entity_class {
    my $self    = shift;
    my $class   = shift;
    return undef if ( ! defined $class);
    my @permitted   = (qw(
        userdef
        ghostbuster
    ));
    return grep {/$class/i} @permitted;
}

1;


