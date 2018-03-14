package Scot::Parser::Generic;

use lib '../../../lib';
use HTML::TreeBuilder;
use Moose;

extends 'Scot::Parser';

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    return 1;
}

sub parse_message {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $body;
    if ( defined $href->{body_plain} ) {
        $body   = $href->{body_plain};
    }
    else {
        my $html    = $href->{body_html};
        my $tree    = HTML::TreeBuilder->new;
        $tree->parse_content($html);
        $body   = $tree->as_text;
    }

    my %json    = (
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $body,
        data        => [{
            sender  => $href->{from},
            alert   => $body,
            columns => [qw(sender alert)],
        }],
        source      => [ qw(email generic) ],
    );

    $log->trace("Parsing generic email");

    return wantarray ? %json : \%json;
}

sub get_sourcename {
    return "generic";
}
1;

