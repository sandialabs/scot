package Scot::Controller::Auth::Ldap;

use lib '../../../../lib';
# use v5.18;
use strict;
use warnings;

use MIME::Base64;
use Net::LDAP;
use Scot::Model::User;

use base 'Scot::Controller::Auth';

=item B<check>

Get called on every route under /scot
Does only one thing: Check for the presence of the 
the user variable in the session cookie.
That is only set if user has authenticated.

=cut

sub check {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $user    = $self->session('user');
    
    $log->trace("Checking Login Status");

    if (defined $user) {
        $self->update_lastvisit($user);
        $log->trace("[User $user] has logged in");
        return 1;
    }

    $log->trace("New or expired session,...");

    my $req     = $self->req;
    my $url     = $req->url->to_string();
    $log->trace("Login Form will redirect after auth to url = $url");
    $self->session(orig_url => $url);


    $self->redirect_to('login');
    return 0;
}

=item B<login>

This will render the login in page

=cut

sub login {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = $self->session('orig_url');
    $log->trace("Trying to render Login Form url = $url");
    $self->render( orig_url => $url );
}

=item B<logout>

You can now expire you session cookie!
Log out has been achieved

=cut

sub logout {
    my $self    = shift;
    $self->session(expires => 1);
    $self->session(user => '');
    $self->redirect_to('/login');
}

=item B<auth>

this gets called by posting the form rendered in the login method
if you auth, you get a session cookie
if not, no scot for you

=cut

# need to put some rate limiter in here and or lock outs

sub auth {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $path    = $self->req->url->path;

    $log->trace("Authentication Check Begins");

    my $user    = $self->param('user');
    my $pass    = $self->param('pass');
    my $orig_url= $self->session('orig_url');

    $log->trace("Got user = $user orig_url = $orig_url");

    unless ( defined $user and defined $pass ) {
        return $self->failed_auth(
            "Undefined user or pass",
            $user, 
            $pass);
    }

    $user = lc($user);  # force to lc for consistency

    # stip leading and trailing whitespace
    $pass =~ s/^\s+(\w+)\s+$/$1/;

    if ( $self->has_invalid_user_chars($user) ) {
        return $self->failed_auth("Invalid chars in username", $user);
    }

    if ( length($pass) > 32 or length($user) > 32) {
        return $self->failed_auth(
            "Pass or User was longer than 32 chars",
            $user, 
            $pass);
    }

    if ( defined( $self->env->ldap ) ) {
        $log->trace("attempting ldap auth for user $user");
        if ( $self->ldap_authenticates($user, $pass) ) {
            my $group_aref = $env->ldap->get_users_groups($user);
            $self->session('groups' => $group_aref);
            return $self->sucessful_auth($user, $orig_url);;
        }
    }
    else {
        $log->error("ERROR ldap not defined, yet your are trying to auth using it");
    }

    $log->error("Failed LDAP AUTH");
    return $self->failed_auth(
        "attempt to authenticate $user via LDAP failed",
        $user,
        $pass);
}

sub failed_auth {
    my $self    = shift;
    my $msg     = shift;
    my $user    = shift;
    my $pass    = shift;
    my $log     = $self->env->log;

    $log->error("FAILED AUTH: $msg");
    $log->debug("User: $user Pass: -----");

    $self->update_user_failure($user);

    $self->flash("Invalid Login");
    $self->redirect_to('/login');
    return;
}

sub sucessful_auth {
    my $self    = shift;
    my $user    = shift;
    my $url     = shift;
    my $log     = $self->env->log;

    $log->debug("User $user sucessfully authenticated");

    $self->update_user_sucess($user);
    $self->session( 
        user        => $user, 
    #    groups      => $self->get_user_groups($user),
        secure      => 1,
        expiration  => 3600 * 4,
    );

    $self->redirect_to($url); 
    return;
}

sub get_user_groups {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;

    if ( $env->ldap ) {
        return $env->ldap->get_users_groups($user);
    }
    else {
    }
}

sub ldap_authenticates {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;

    my $ldap    = $self->env->ldap;
    my $log     = $self->env->log;

    unless (defined $ldap) {
        $log->error("LDAP is not defined!");
        return 0;
    }

    return 0 unless ( $ldap->authenticate_user($user, $pass) ); 

    $log->debug("LDAP has authenticated user $user");

    my $groups  = $ldap->get_scot_groups($user);

    $self->session(
        user    => $user,
        groups  => $groups,
    );
    return 1;
}

1;
