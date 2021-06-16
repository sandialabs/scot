package Scot::Util::CSRFProtection;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app ) = @_;

    my $routes = $app->routes;

    $app->helper(
        'reply.bad_csrf' => sub {
            my ($c) = @_;
            $c->res->code(403);
            $c->render_maybe('bad_csrf')
                or $c->render( text => 'Failed CSRF check' );
            return;
        }
    );

    $routes->add_condition(
        with_csrf_protection => sub {
            my ( $route, $c ) = @_;

            my $csrf = $c->req->headers->header('X-CSRF-Token')
                || $c->param('csrf_token');

            unless ( $csrf && $csrf eq $c->csrf_token ) {
                $c->reply->bad_csrf;
                return;
            }

            return 1;
        }
    );

    $routes->add_shortcut(
        with_csrf_protection => sub {
            my ($route) = @_;
            # mojo 9
            # return $route->requires( with_csrf_protection => 1 );
            return $route->requires( with_csrf_protection => 1 );
        }
    );

    return;
}

1;
