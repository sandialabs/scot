package Scot::Util::ElasticSearch;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Moose;
use Mojo::JSON qw/decode_json encode_json/;
use Search::Elasticsearch;
use Scot::Env;
use Data::Dumper;
use Try::Tiny;
use Try::Tiny::Retry;
use namespace::autoclean;

has es   => (
    is      => 'ro',
    isa     => 'Search::Elasticsearch::Client::2_0::Direct',
    required    => 1,
    lazy    => 1,
    builder => '_build_es',
);

has env     => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
    default => sub { Scot::Env->instance },
);

sub _build_es {
    my $self    = shift;
    my $log     = $self->env->log;
    my $es;

    $log->debug("Creating ES client");

    try {
        $es  = Search::Elasticsearch->new();
    }
    catch {
        $log->error("Error creating Elasticsearch client: $_");
        return undef;
    };
    return $es;
}


sub index {
    my $self    = shift;
    my $type    = shift;    # collection
    my $href    = shift;    # the mongo json document
    my $index   = shift // 'scot'; # allow for submitting to a test index
    my $log     = $self->env->log;
    my $es      = $self->es;
    
    my %msg = (
        index   => $index,
        type    => $type,
        id      => $href->{id},
        body    => $href,
    );

    $log->trace("Sending ES INDEX message: ",{filter=>\&Dumper, value=>\%msg});

    $es->index(%msg);

}

sub search {
    my $self    = shift;
    my $body    = shift;    # elastic search query doc
    my $index   = shift // 'scot';
    my $es      = $self->es;
    my $log     = $self->env->log;

    my %msg = (
        index   => $index,
        body    => $body,
    );

    $log->debug("Searching ES for ", {filter=>\&Dumper, value => \%msg});

    my $results = $es->search(%msg);
    return $results;
}

sub delete_index {
    my $self    = shift;
    my $index   = shift;
    my $es      = $self->es;
    $es->indices->delete(index=>$index);
}



__PACKAGE__->meta->make_immutable;
1;        

__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

