package Scot;

use strict;
use warnings;
use v5.18;

use Carp qw(cluck longmess shortmess);
use Mojo::Base 'Mojolicious';
use Mojo::Cache;
use Scot::Env;
use Data::Dumper;


=head1 Scot.pm 

SCOT : Sandia Cyber Omni Tracker

This is the main perl module that comprises the SCOT web application.
It is a child of Mojo::Base and therefore is a Mojolicious based app.

=cut


sub startup {
    my $self    = shift;
    $self->mode('development'); # remove when in prod


    my $env     = Scot::Env->new();
    $self->attr     ( env => sub { $env } );
    $self->helper   ( env => sub { shift->app->env } );
    $| = 1;

    my $cache   = Mojo::Cache->new(max_keys => 100);
    $self->helper   ('cache'  => sub { $cache } );

    my $log = $env->log;
    $self->log($log);
    $self->log_startup($log);

    $self->secrets( $env->mojo->{secrets} );
    $self->sessions->default_expiration( $env->mojo->{default_expiration} );
    $self->sessions->secure(1);


    # Note to future maintainer: 
    # hypnotoad performs preforking.  This can cause problems with DB
    # connections created in Env, IF the DB client can't handle reconnections
    # after forking.  Meerkat for mongo can, but if we have any DBI connection
    # we might have problems.
    $self->config(
        hypnotoad   => {
            listen  => ['http://localhost:3000?reuse=1'],
            workers => 75,
            clients => 1,
            proxy   => 1,
            pidfile => '/var/run/hypno.pid',
        },
    );

    # capture stuff that normally would go to STDERR and put in log
    #$SIG{'__WARN__'} = sub {
    #    do {
    #        no warnings 'uninitialized';
    #        $log->warn(@_);
    #        unless ( grep { /uninitialized/ } @_ ) {
    #            $log->warn(longmess());
    #        }
    #    }
    #};
    #$SIG{'__DIE__'} = sub {
    #    $log->error(@_);
    #    $log->warn(longmess());
    #};


=head2 Scot Application Attributes and Helpers

=over 4 


=item B<get_req_json>

get JSON that was submitted with the web request

=cut

    # convenience helper to get the json out of a request
    $self->helper('get_req_json'    => sub {
        my $self    = shift;
        my $req     = $self->req;
        return $req->json;
    });


=head2 SCOT Routes

=over 4

=cut

    my $authclass   = $env->authclass;

    # routes
    my $r       = $self->routes;

    $r->route( '/login' )   
      ->to ( $authclass.'#login' ) 
      ->name( 'login' );
    $r->route( '/auth' )    
      ->via('post') 
      ->to($authclass.'#auth') 
      ->name('auth');
    
    # make sure that we have passed authentication

    my $auth    = $r->under('/')->to($authclass.'#check');

    # necessary to get default index.html from /opt/scot/public
    # and have it remain so that only authenticated users can see
    $auth   ->get('/')
            ->to( cb => sub {
                my $c = shift;
                $log->debug("Hitting Static /");
                $c->reply->static('index.html');
            });

    # prepends /scot to the routes below
    my $scot    = $auth->any('/scot');

    $scot   ->route ('/api/v2/search')
            ->to    ('controller-search#search')
            ->name  ('search');

    $scot   ->route ('/api/v2/command/:action')
            ->via   ('put')
            ->to    ('controller-api#do_command')
            ->name  ('do_command');

    $scot   ->route ('/api/v2/file')
            ->via   ('post')
            ->to    ('controller-file#upload')
            ->name  ('create');

    $scot   ->route ('/api/v2/:thing')
            ->via   ('post')
            ->to    ('controller-api#create')
            ->name  ('create');

    $scot   ->route ('/api/v2/supertable')
            ->via   ('get')
            ->to    ('controller-api#supertable')
            ->name  ('supertable');

    $scot   ->route ('/api/v2/whoami')
            ->via   ('get')
            ->to    ('controller-api#whoami')
            ->name  ('whoami');

    $scot   ->route ('/api/v2/ac/:thing/:search')
            ->via   ('get')
            ->to    ('controller-api#autocomplete')
            ->name  ('autocomplete');

    $scot   ->route ('/api/v2/:thing/#id')
            ->via   ('get')
            ->to    ('controller-api#get_one')
            ->name  ('get_one');

    $scot   ->route ('/api/v2/:thing')
            ->via   ('get')
            ->to    ('controller-api#get_many')
            ->name  ('get_many');

    $scot   ->route ('/api/v2/:thing/:id/:subthing')
            ->via   ('get')
            ->to    ('controller-api#get_subthing')
            ->name  ('get_subthing');

    $scot   ->route ('/api/v2/:thing/:id')
            ->via   ('put')
            ->to    ('controller-api#update')
            ->name  ('update');

    $scot   ->route ('/api/v2/:thing/:id/:subthing/:subid')
            ->via   ('delete')
            ->to    ('controller-api#breaklink')
            ->name  ('delete');

    $scot   ->route ('/api/v2/:thing/:id')
            ->via   ('delete')
            ->to    ('controller-api#delete')
            ->name  ('delete');

}

sub log_startup {
    my $self    = shift;
    my $log     = shift;

    $log->info(
                "============================================================\n".
        " "x55 ."| SCOT  ". $self->env->version . "\n".
        " "x55 ."| mode: ". $self->env->mode. "\n".
        " "x55 ."| db:   ". 
                    Dumper($self->env->config) . "\n".
        " "x55 ."============================================================\n"
    );
    # $self->env->dump_env;
}

1;   

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2015.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::API>

=item L<Scot::Env>

=back

