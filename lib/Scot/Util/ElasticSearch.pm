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
    is          => 'ro',
    isa         => 'Search::Elasticsearch::Client::2_0::Direct',
    required    => 1,
    lazy        => 1,
    builder     => '_build_es',
);

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
);

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {
        {
            nodes   => [ '127.0.0.1:9200',
                         'localhost:9200' ],
        };
    },
);

sub _build_es {
    my $self    = shift;
    my $log     = $self->log;
    my $es;

    $log->debug("Creating ES client");

    my @noproxy = map { m/^(.*):\d+$/ } @{$self->config->{nodes}};
    $ENV{'no_proxy'} = join ',', @noproxy;

    my %conparams   = (
        nodes   => $self->config->{nodes},
        cxn_pool    => 'Sniff',
        log_to  => 'Stderr',
    );

    try {
        $es  = Search::Elasticsearch->new(%conparams);
        $es->ping;
    }
    catch {
        $log->error("Error creating Elasticsearch client: $_");
        return undef;
    };
    $log->debug("ES is ",{filter=>\&Dumper, value=>$es});
    return $es;
}


sub index {
    my $self    = shift;
    my $type    = shift;    # collection
    my $href    = shift;    # the mongo json document
    my $index   = shift // 'scot'; # allow for submitting to a test index
    my $log     = $self->log;
    my $es      = $self->es;
    
    my %msg = (
        index   => $index,
        type    => $type,
        id      => $href->{id},
        body    => $href,
    );

    $log->debug("Sending ES INDEX message: ",{filter=>\&Dumper, value=>\%msg});

    $es->index(%msg);

}

sub delete {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $index   = shift // 'scot';
    my $log     = $self->log;
    my $es      = $self->es;

    $log->debug("Deleting $type $id from $index");

    my %msg = (
        index   => $index,
        type    => $type,
        id      => $id,
    );

    $es->delete(%msg);
}

sub search {
    my $self    = shift;
    my $body    = shift;    # elastic search query doc
    my $index   = shift // 'scot';
    my $es      = $self->es;
    my $log     = $self->log;

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

