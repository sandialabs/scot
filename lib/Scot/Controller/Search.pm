package Scot::Controller::Search;


=head1 Name

Scot::Controller::Search

=head1 Description

Proxy Search requests to elasticsearch

=cut

use Data::Dumper;
use Try::Tiny;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper::HTML qw(dumper_html);
use strict;
use warnings;
use base 'Mojolicious::Controller';

=head1 Routes

=over 4

=item I<POST> B<POST /scot/api/v2/_search>

=cut

sub search {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');

    $log->trace("------------");
    $log->trace("Handler is processing a POST (search) from $user");
    $log->trace("------------");

    my $request = $self->req;

    $log->debug("Search request: ",{filter=>\&Dumper, value=>$request});

    my $body    = $request->body;

    $log->debug("Search body: ",{filter => \&Dumper, value=>$body});

    my $params  = $request->params->to_hash;

    $log->debug("Search Params: ",{filter=>\&Dumper, value=>$params});

    my $response = $esua->do_request(  # ... href of json returned.
        'POST',
        '',
        {
            params  => $params,
            json    => $body,
        },
    ); 

    $log->debug("Got Response: ", {filter=>\&Dumper, value=>$response});

    $self->do_render($response);


}

1;
