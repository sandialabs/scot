package Scot::Email::Parser::Email822;

use strict;
use warnings;
use Data::Dumper;
use HTML::Element;
use URI;
use Moose;

extends 'Scot::Email::Parser';

sub parse {
    my $self    = shift;
    my $msg     = shift;

    my ($courriel, $html, $plain) = $self->get_body($msg->{message_str});

    if ( $self->body_not_html($html)) {
        $html   = $self->wrap_non_html($html);
    }

    my $tree        = $self->build_html_tree($html);

    my $subject     = $courriel->subject
    my $tags        = ['822attachment'];
    my $sources     = [ 'email', $courriel->{from} ];

    my $attachments = $self->handle_attachments($courriel, $msg, $tree);
    my $entry_data  = $self->build_entry($tree);


    my %json    = (
        entry       => $entry_data,
    );
    return wantarray ? %json : \%json;
}


sub build_entry {
    my $self    = shift;
    my $tree    = shift;
     
    # hack
    no warnings;
    my $new     = $tree->as_HTML;

    return { body => $new };
}

sub handle_attachments {
    my $self        = shift;
    my $courriel    = shift;
    my $msg         = shift;
    my $tree        = shift;
    my $log         = $self->env->log;

    return;
}


sub wrap_non_html {
    my $self    = shift;
    my $html    = shift;
    return qq{<html><body><pre>$html</pre></body></html>};
}

1;



