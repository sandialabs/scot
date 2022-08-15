package Scot::Email::Parser;

use strict;
use warnings;

use HTML::TreeBuilder;
use Courriel;
use Moose;
use Try::Tiny;
use utf8;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
);

sub build_html_tree {
    my $self    = shift;
    my $body    = shift;
    my $log     = $self->env->log;

    $log->debug("building html tree");

    if ( ! defined $body ) {
        $log->error("NO BODY TO PARSE!");
        return undef;
    }

    my $tree    = HTML::TreeBuilder->new;
    $tree       ->implicit_tags(1);
    $tree       ->implicit_body_p_tag(1);
    $tree       ->parse_content($body);

    unless ( $tree ) {
        $log->error("Unable to Parse HTML!");
        $log->error("Body = $body");
        return undef;
    }
    return $tree;
}

sub clean_messagestr {
    my $self    = shift;
    my $mstr    = shift;
    my $clean   = (utf8::is_utf8($mstr)) ?
        Encode::encode_utf8($mstr) :
        $mstr;
    # strip any ^M from windows polluted 
    $clean =~ s///g;
    return $clean;
}

sub get_body {
    my $self    = shift;
    my $mstr    = shift;
    my $log     = $self->env->log;

    $log->debug("getting body");
    $log->trace("mstr = $mstr");

    my $clean = $self->clean_messagestr($mstr);
    $log->trace("clean = $clean");

    my $email       = try {
        # Courriel->parse(text => $clean);
        # see if Courriel handles the cleaning better
        Courriel->parse(text => $mstr);
    }
    catch {
        $log->error("Courriel parse error: $_");
    };

    if ( defined $email and ref($email)) {
        $log->debug("Courriel object parsed");
        my $htmlpart    = $email->html_body_part();
        my $plainpart   = $email->plain_body_part();

        my $html  = $htmlpart->content if $htmlpart;
        my $plain = $plainpart->content if $plainpart;

        return $email, $html, $plain;
    }
    else {
        $log->error("Courriel failed parsing");
        return undef, undef, undef;
    }
}

sub body_not_html {
    my $self    = shift;
    my $html    = shift;
    my $log     = $self->env->log;

    if ( ! defined $html ) {
        $log->warn("HTML BODY is NULL!");
        return 1;
    }
    return ! ($html =~ /\<html.*\>/i or $html =~ /DOCTYPE html/);
}
1;
