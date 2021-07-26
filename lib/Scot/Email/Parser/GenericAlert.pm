package Scot::Email::Parser::GenericAlert;

use lib '../../../lib';
use strict;
use warnings;

use Data::Dumper;
use Moose;
extends 'Scot::Email::Parser';

sub parse {
    my $self    = shift;
    my $msg     = shift;
    my $log     = $self->env->log;

    $log->debug(ref($self)." parsing begins");

    my ($courriel, $html, $plain ) = $self->get_body($msg->{message_str});

    if ( $self->body_not_html($html) ) {
        $html = $self->wrap_non_html($html,$plain);
        $log->trace("Wrapped non html email like this: ".$html);
    }

    my $columns = [ 'alert_text' ];
    my $alerts  = [
        {
            columns     => $columns,
            alert_text  => $html,
        },
    ];
    my $tags        = [ 'generic_alert' ];
    my @splunklinks = [];

    my %json    = (
        subject => $msg->{subject},
        data    => $alerts,
        columns => $columns,
        tag     => $tags,
        ahrefs  => \@splunklinks,
        body    => $html,
        body_plain  => $plain,
        message_id  => $msg->{message_id},
    );

    if ( $self->document_too_large(\%json) ) {
        $log->warn("Alertgroup Document too large! Trimming body");
        $json{body}       = qq|Email body too large, view in email client.|;
        $json{body_plain} = qq|Email body too large, view in email client.|;
        if ( $self->document_too_large(\%json) ) {
            $log->error("Trimming document did not reduce sufficiently");
        }
    }

    # $log->debug("json is ",{filter=>\&Dumper, value=>\%json});
    return wantarray ? %json : \%json;
}

sub document_too_large {
    my $self    = shift;
    my $doc     = shift;
    my $size    = 
        length($doc->{subject}) + 
        length($doc->{body}) + 
        length($doc->{body_plain}) +
        length($doc->{message_id});

    $self->env->log->debug("approx size is $size");

    return ($size > 1000000);
}

sub wrap_non_html {
    my $self    = shift;
    my $html    = shift;
    my $plain   = shift;

    my $text    = (defined $html) ? $html : (defined $plain) ? $plain : '-not-found-';
    my $new     = qq{
        <html>
         <body>
          <pre>
            $text
          </pre>
         </body>
        </html>
    };
    return $new;
}


1;
