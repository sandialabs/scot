package Scot::Controller::Flair;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);
use Scalar::Util qw(looks_like_number);
use MIME::Base64;
use Scot::Util::EntityExtractor;

use base 'Mojolicious::Controller';

=head1 Scot::Controller::Flair

Pass posted data into EntityExtractor

=head2 Methods

=over 4

=item B<scatchpad>

handle the data from scratchpad.html

=cut

sub scratchpad  {
    my $self    = shift;
    my $log     = $self->env->log;
    my $req     = $self->req;
    my $html    = $req->param("input");;
    $log->debug("INPUT is ".$html);
    my $ee      = $self->env->entity_extractor;
    my $href    = $ee->process_html($html);
    $self->render( json => $href );
}

1;

