package Scot::Flair::Extractor;

use strict;
use warnings;
use utf8;
use lib '../../../lib';

use Data::Dumper;
use Try::Tiny;
use namespace::autoclean;
use Scot::Flair::Io;
use Domain::PublicSuffix;
use HTML::Entities;
use HTML::Element;
use HTML::TreeBuilder;
use HTML::FormatText;
use Moose;

my @ss = (); # see "Mastering Regular Expressions", 3rd Edition, Chpt. 7

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has scot_regex => (
    is              => 'ro',
    isa             => 'Scot::Flair::Regex',
    required        => 1,
);

has splitre => (
    is          => 'ro',
    isa         => 'RegexpRef',
    required    => 1,
    builder     => '_build_splitre',
);

sub _build_splitre {
    my $self    = shift;
    return qr{
        (
        [ \t\n]                        # spaces/tabs/newline
        | \W                           # or nonword chars
        | [\+\=\@\w\.\[\]\(\)\{\}-]+   # or words with embedded periods,dashes
                                       # with potential obsfucation [({})]
        )
    }xms;
}

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

sub process_html {
    my $self    = shift;
    my $html    = shift;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("process_html");

    my %edb = (
        entities => [],
    );   # entity db

    $html       = $self->clean_html($html);
    my $tree    = $self->build_html_tree($html);

    $self->walk_tree($tree, \%edb);

    $edb{text}  = $self->generate_plain_text($tree);
    $edb{flair} = $self->generate_new_html($tree);

    &$timer;

    return \%edb;
}

sub clean_html {
    my $self    = shift;
    my $html    = shift;
    my $log     = $self->env->log;

    my $clean = (utf8::is_utf8($html)) ? 
        Encode::encode_utf8($html)     :
        $html;

    $log->debug("html  = ", {filter=>\&Dumper, value => $html});

    if ( $clean !~ /^<.*>/ ) {
        $self->env->log->debug("plain text, detected, wrapping");
        $clean = "<html>".encode_entities($clean)."</html>";
    }

    $log->debug("clean = ", {filter=>\&Dumper, value => $clean});

    return $clean;
}

sub build_html_tree {
    my $self    = shift;
    my $html    = shift;
    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($html);
       $tree    ->elementify;
    return $tree;
}

sub generate_plain_text {
    my $self    = shift;
    my $tree    = shift;
    my $fmt     = HTML::FormatText->new();
    my $text    = $fmt->format($tree);
    return $text;
}

sub generate_new_html {
    my $self    = shift;
    my $tree    = shift;
    my $body    = $tree->look_down('_tag', 'body');
    my $div     = HTML::Element->new('div');
    $div->push_content($body->detach_content);
    my $new     = $div->as_HTML();
    return $new;
}

sub walk_tree {
    my $self    = shift;
    my $element = shift;
    my $edb     = shift;
    my $level   = shift;
    my $log     = $self->env->log;

    $level += 1;
    my $spaces = $level * 4;
    $self->trace_decent($element, $spaces);

    if ( $element->is_empty ) {
        $log->trace(" "x$spaces."---- empty node ----");
        return;
    }

    $element->normalize_content;
    my @content = $element->content_list;
    my @new     = ();

    for (my $index = 0; $index < scalar(@content); $index++ ) {

        $log->trace(" "x$spaces."Index $index");

        if ( $self->is_not_leaf_node($content[$index]) ) {
            my $child   = $content[$index];

            $self->fix_weird_html($child);

            if ( ! $self->user_defined_entity_element($child, $edb) ) {
                $log->trace(" "x$spaces."Element ".$child->address." found, recursing.");
                $self->walk_tree($child, $edb, $level);
            }

            push @new, $child;
        }
        else {
            my $text = $content[$index];
            $log->trace(" "x$spaces."Leaf Node content = ".$text);
            push @new, $self->parse($text, $edb);
        }
    }
    # replace the content of the element
    $element->splice_content(0, scalar(@content), @new);
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

    $self->add_entity($edb, $type, $value);
    $child->attr('class', "entity $class");
    return 1;
}

sub external_defined_entity_class {
    my $self    = shift;
    my $class   = shift;
    my @permitted   = (qw(
        userdef
        ghostbuster
    ));
    return grep {/$class/i} @permitted;
}

sub is_not_leaf_node {
    my $self    = shift;
    my $data    = shift;
    return ref($data);
}

sub fix_weird_html {
    my $self    = shift;
    my $child   = shift;
    my $log     = $self->env->log;

    $log->trace("looking at child for weird html");

    my @content = $child->content_list;

    # $log->debug("contents: ",{filter => \&Dumper, value => \@content});

    return if ($self->fix_splunk_ipv4($child, @content));
    return if ($self->fix_splunk_ipv6($child, @content));
}

sub fix_splunk_ipv4 {
    my $self    = shift;
    my $child   = shift;
    my @content = @_;
    my $found   = 0;
    my $log     = $self->env->log;

    for (my $i = 0; $i < scalar(@content) - 6; $i++) {
        if ( $self->has_splunk_ipv4_pattern($i, @content) ) {
            my $new_ipaddr = join('.',
                $content[$i]->as_text,
                $content[$i+2]->as_text,
                $content[$i+4]->as_text,
                $content[$i+6]->as_text);
            $child->splice_content($i, 7, $new_ipaddr);
            $found++;
        }
    }
    return $found;
}

sub has_splunk_ipv4_pattern {
    my $self    = shift;
    my $i       = shift;
    my @c       = @_;
    my $log     = $self->env->log;

    return undef if ( ! ref($c[$i]) );

    $log->debug("c[$i] = ".$c[$i]->tag);
    $log->debug("c[$i+6] = ".$c[$i]->tag);
    
    return undef if ( $c[$i]->tag   ne 'em');
    return undef if ( $c[$i+1]      ne '.');
    return undef if ( $c[$i+2]->tag ne 'em');
    return undef if ( $c[$i+3]      ne '.');
    return undef if ( $c[$i+4]->tag ne 'em');
    return undef if ( $c[$i+5]      ne '.');
    return undef if ( $c[$i+6]->tag ne 'em');
    return 1;
}

sub fix_splunk_ipv6 {
    my $self    = shift;
    my $child   = shift;
    my @content = @_;
    my $found   = 0;

    for (my $i = 0; $i < scalar(@content) - 8; $i++) {
        if ( $self->has_splunk_ipv4_pattern($i, @content) ) {
            my $new_ipaddr = join('.',
                $content[$i]->as_text,
                $content[$i+2]->as_text,
                $content[$i+4]->as_text,
                $content[$i+6]->as_text,
                $content[$i+7]->as_text,
                $content[$i+8]->as_text);
            $child->splice_content($i, 7, $new_ipaddr);
            $found++;
        }
    }
    return $found;
}

sub has_splunk_ipv6_pattern {
    my $self    = shift;
    my $i       = shift;
    my @c       = @_;
    
    return undef if ( ! ref($c[$i]) );
    return undef if ( $c[$i]->tag   ne 'span');
    return undef if ( $c[$i+1]      ne ':');
    return undef if ( $c[$i+2]->tag ne 'span');
    return undef if ( $c[$i+3]      ne ':');
    return undef if ( $c[$i+4]->tag ne 'span');
    return undef if ( $c[$i+5]      ne ':');
    return undef if ( $c[$i+6]->tag ne 'span');
    return undef if ( $c[$i+7]      ne '0:0:0' and 
                      $c[$i+7]      !~ /([0-9a-f]{1,4}:){3}/i );
    return undef if ( $c[$i+8]->tag ne 'span');
    return 1;
}


sub trace_decent {
    my $self    = shift;
    my $element = shift;
    my $spaces  = shift;
    my $log     = $self->env->log;
    $log->trace(" "x$spaces . "Walking Node: ".$element->starttag." (".$element->address.")");
}

sub parse {
    my $self    = shift;
    my $text    = shift;
    my $edb     = shift;
    my @new     = ();

    return @new if ( $text =~ /^[\t\n ]$/);

    push @new, $self->find_multi_word_matches($text, $edb);
    if (scalar(@new) < 1) {
        push @new, $self->find_single_word_matches($text, $edb);
    }
    return wantarray ? @new : \@new;
}

sub find_multi_word_matches {
    my $self    = shift;
    my $text    = shift;
    my $edb     = shift;
    my @new     = ();
    my $mw_regexes  = $self->scot_regex->multi_word_regexes;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("multi word matches");

    $log->trace("looking for multi word matches");
    $log->debug(scalar(@$mw_regexes)." MW Regexes to check");

    REGEX:
    foreach my $href (@$mw_regexes) {
        my $regex   = $href->{regex};
        my $type    = $href->{type};

        $log->trace("applying $type to $text");

        my ( $pre,
             $match,
             $post ) = $self->attempt_match($text, $regex);

        if (! defined $match ) {
            next REGEX;
        }

        $log->trace("match = $match");

        my $span = $self->post_mw_match_actions($match, $type, $edb);

        if ( ! defined $span ) {
            $self->env->log->warn("Problem with mw match, skipping to next regex");
            next REGEX;
        }

        # recurse into pre and post looking for additional matches
        push @new, $self->parse($pre, $edb);
        push @new, $span;
        push @new, $self->parse($post, $edb);
        # we reach this point we have found all possible matches so quit;
        last REGEX;
    }
    &$timer;
    return wantarray ? @new : \@new;
}

sub attempt_match {
    my $self    = shift;
    my $text    = shift;
    my $regex   = shift;
    my $log     = $self->env->log;

    if ( $text =~ m/$regex/ ) {
        my $pre     = substr($text, 0, $-[0]);
        my $match   = substr($text, $-[0], $+[0] - $-[0]);
        my $post    = substr($text, $+[0]);

        return $pre, $match, $post;
    }
    return undef, undef, undef;
}

sub post_mw_match_actions {
    my $self    = shift;
    my $match   = shift;
    my $type    = shift;
    my $edb     = shift;
    my $log     = $self->env->log;

    if ( $type eq "cidr" ) {
        my $span = $self->cidr_action($match, $edb);
        if (! defined $span ) {
            $log->warn("Problem with CIDR match!");
            return undef;
        }
        return $span;
    }

    my $span = $self->create_span($match, $type);
    $self->add_entity($edb, $type, $match);
    return $span;
}

sub cidr_action {
    my $self    = shift;
    my $match   = shift;
    my $edb     = shift;

    my $cidr = $self->deobsfucate_ipdomain($match);
    $self->add_entity($edb, 'cidr', $cidr);
    return $self->create_span($cidr, 'cidr');
}

sub add_entity {
    my $self    = shift;
    my $edb     = shift;
    my $type    = shift;
    my $match   = shift;
    push @{ $edb->{entities} } , {
        type    => $type,
        value   => lc($match),
    };
}

sub deobsfucate_ipdomain {
    my $self    = shift;
    my $text    = shift;
    my @parts   = split(/[\[\(\{]*\.[\]\)\}]*/, $text);
    my $clear   = join('.',@parts);
    return $clear;
}

sub find_single_word_matches {
    my $self    = shift;
    my $text    = shift;
    my $edb     = shift;
    my @new     = ();
    my $splitre = $self->splitre;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("single word matches");
    $log->trace("looking for single word matches");

    my @words   = ( $text =~ m/$splitre/g );
    $log->debug(scalar(@words)." words to check");

    WORD:
    foreach my $word (@words) {
        my @found = $self->apply_regex_to_word($word,$edb);
        if (scalar(@found)>0) {
            push @new, @found;
        }
        else {
            push @new, $word;
        }
    }
    &$timer;
    return wantarray ? @new : \@new;
}

sub apply_regex_to_word {
    my $self    = shift;
    my $word    = shift;
    my $edb     = shift;
    my $regexes = $self->scot_regex->single_word_regexes;
    my @new     = ();
    my $log     = $self->env->log;

    $log->debug(scalar(@$regexes)." SW Regexes to check");

    REGEX:
    foreach my $href (@$regexes) {
        my $regex   = $href->{regex};
        my $type    = $href->{type};

        $log->trace("applying regex $type to $word");

        my ($pre,
            $match, 
            $post ) = $self->attempt_match($word, $regex);

        if (! defined $match ) {
            next REGEX;
        }

        $log->debug("matches $type");

        my $span = $self->post_sw_match_actions($match, $type, $edb);

        if ( ! defined $span ) {
            $self->env->log->warn("Problem with sw match, skipping to next regex");
            next REGEX;
        }

        push @new, $pre if ($pre ne '');
        push @new, $span;
        push @new, $post if ($post ne '');
        last REGEX;
    }
    return wantarray ? @new : \@new;
}

sub post_sw_match_actions {
    my $self    = shift;    
    my $match   = shift;
    my $type    = shift;
    my $edb     = shift;

    if ( $type eq "domain" ) {
        my $span = $self->domain_action($match, $edb);
        return $span;
    }

    if ( $type eq "ipaddr" ) {
        my $span = $self->ipaddr_action($match, $edb);
        return $span;
    }

    if ( $type eq "cidr" ) {
        my $span = $self->cidr_action($match, $edb);
        return $span;
    }

    if ( $type eq "email" ) {
        my $span = $self->email_action($match, $edb);
        return $span;
    }

    my $span = $self->create_span($match, $type);
    $self->add_entity($edb, $type, $match);
    return $span;
}

sub domain_action {
    my $self    = shift;
    my $domain  = shift;
    my $edb     = shift;
    my $log     = $self->env->log;
    my $pds     = $self->public_suffix;

    $domain = $self->deobsfucate_ipdomain($domain);

    $log->trace("validating potential domain: $domain");

    return try {
        my $root = $self->get_root_domain($domain);
        if ( ! defined $root ) {
            $log->error("Error Getting root domain: ".$pds->error);
            return undef;
        }
        $self->add_entity($edb, "domain", $domain);
        return $self->create_span($domain, "domain");
    }
    catch {
        $log->warn("Error matching root domain: $_");
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

sub email_action {
    my $self    = shift;
    my $email   = shift;
    my $edb     = shift;
    my $log     = $self->env->log;

    $log->trace("EMAIL ACTION on $email");

    my ( $user, $domain ) = split(/\@/, $email);

    $log->debug("user = $user, domain =$domain");

    $domain = $self->deobsfucate_ipdomain($domain);
    my $domain_span = $self->create_span($domain, "domain");
    $self->add_entity($edb, "domain", $domain);

    my $new_email = lc($user . '@' . $domain);
    my $email_span = HTML::Element->new(
        'span',
        'class' => 'entity email',
        'data-entity-type' => 'email',
        'data-entity-value' => $new_email,
    );
    $email_span->push_content($user, '@', $domain_span);
    $self->add_entity($edb, "email", $new_email); # ??? should this be just "$email"
    return $email_span;
}

sub ipaddr_action {
    my $self    = shift;
    my $ipaddr  = shift;
    my $edb     = shift;

    my $clean   = $self->deobsfucate_ipdomain($ipaddr);
    $self->add_entity($edb, "ipaddr", $clean);
    return $self->create_span($clean, "ipaddr");
}

sub create_span {
    my $self    = shift;
    my $text    = shift;
    my $type    = shift;
    my $element = HTML::Element->new(
        'span',
        'class' => "entity $type",
        'data-entity-type'  => $type,
        'data-entity-value' => lc($text),
    );
    $element->push_content($text);
    return $element;
}


1;
