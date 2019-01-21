package Scot::Controller::Auth::Remoteuser;

use lib '../../../../lib';
use strict;
use warnings;

use MIME::Base64;
use Net::LDAP;
use Digest::SHA qw(sha512_hex);
use Crypt::PBKDF2;
use Scot::Model::User;
use Data::Dumper;

use base 'Scot::Controller::Auth';

=head1 RemoteUser

this authentication module respects the REMOTE_USER header
This allows us to work with sso systems and mod_ssl CA client auth
relies on basic auth and apache to do the heavy lifting

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

    $log->debug("Authentication check begins");

    my $request     = $self->req;
    my $headers     = $request->headers;

    unless ( $self->check_for_csrf ) {
        $log->error("CSRF attempt! from ", $self->tx->remote_address);
        return undef;
    }


    $log->debug("headers = ".Dumper($headers));

    my $basicauth   = $headers->header('authorization');
    my $authuser    = $headers->header('authuser');
    my $remoteuser  = $headers->header('remote-user');
    my $user        = $self->session('user');

    $log->debug("\n".
                " authorization = $basicauth \n".
                " authuser      = $authuser \n".
                " remote user   = $remoteuser \n".
                " session user  = $user \n");

    unless ( defined $user ) {
        $log->warn("No Session User present, will look for alternatives");
        if ( defined $remoteuser ) {
            $log->warn("Using value of header remote-user as username");
            $user   = $remoteuser;
        }
        else {
            if ( defined $authuser ) {
                $log->warn("using vale of header authuser as username");
                $user = $authuser;
            }
            else {
                $log->error("I don not know who is attempting access!");
                return undef;
            }
        }
    }

    $log->debug("Session user is ", {filter =>\&Dumper, value =>$user});
    $self->session('user'   => $user);

    my $groups  = $self->session('groups');
    unless (ref($groups) eq "ARRAY") {
        $log->debug("groups not set in session, fetching");
        my $garef	= $self->get_groups($user);
        $self->session('groups'	=> $garef);
        $groups	= $garef;
    }
    $log->debug("Session groups is ", {filter =>\&Dumper, value =>$groups});

    # user must be in at least 1 "scot" group
    if ( scalar( @{$groups} ) >0 ) {
        $log->debug("User appears legit");
        return 1;
    }
    $log->error("User $user failed auth check");
    return undef;
}

sub login {
    my $self    = shift;
    my $href    = { status => "fail" };
    if ( $self->check ) {
        $href->{status} = "ok";
    }
    $self->render( json => $href);
}

sub logout {
    my $self    = shift;
    $self->session('user' => '');
    $self->session('groups' => '');
    $self->session(expires => 1);
}

sub get_groups {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $gmode   = $env->group_mode;
    my @groups;

    $log->debug("getting $user groups");
    $log->debug("Group mode is $gmode");

    if ( $gmode eq "ldap" ) {
        $log->debug("group mode is ldap");
        my $ldap    = $env->ldap;

        unless ( defined $ldap ) {
            $log->error("GROUP mode is LDAP, but LDAP is not defined!");
            return wantarray ? ():[];
        }

        my $results = $ldap->get_users_groups($user);
        if ( $results < 0 ) {
            $log->error("GOT ERROR FROM LDAP!");
            return wantarray ? () :[];
        }
        
        $log->debug("got ". join(',', grep {/scot/i} @$results));
        push @groups, grep {/scot/i} @$results;
        return wantarray ? @groups : \@groups;
    }

    # else local is all that remains
    $log->debug("group mode is local");
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('User');
    my $userobj = $col->find_one({username => $user});
    my $groups  = $userobj->groups;

    $log->debug("got ".join(',',@$groups));
    return wantarray ? @$groups : \@$groups;
}

1;
