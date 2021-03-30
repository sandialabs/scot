package Scot::Email::Parser;

use lib '../../lib';
use strict;
use warnings;

use Moose;

=head1 Scot::Email::Parser

The parent class for Email parsers

=cut

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    # default   => sub { Scot::Env->instance; },
);

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;

    $log->logdie("Child class must implement will_parse");
}

sub build_html_tree {
    my $self    = shift;
    my $body    = shift;
    my $log     = $self->env->log;
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




1;
