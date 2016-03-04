package Scot::Util::Ldap;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Net::LDAP;
use Moose;

has hostname    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'sec-ldap-nm.sandia.gov',
);

has dn          => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'cn=snlldapproxy,ou=local config,dc=gov',
);

has password    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'snlldapproxy',
);

has scheme      => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'ldap',
);

has group_search    => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {
        base    => 'ou=groups,ou=snl,dc=nnsa,dc=doe,dc=gov',
        filter  => '(| (cn=wg-scot*))',
        attrs   => [ 'cn' ],
    }},
);

has user_groups => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {
        base    => 'ou=accounts,ou=snl,dc=nnsa,dc=doe,dc=gov',
        filter  => 'uid=%s',
        attrs   => [ 'memberOf' ],
    }},
);

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    default     => sub { Scot::Env->instance },
);

has 'ldap'  => (
    is          => 'rw',
    isa         => 'Maybe[Net::LDAP]',
    required    => 1,
    lazy        => 1,
    builder     => '_build_LDAP',
);

sub _build_LDAP {
    my $self    = shift;
    my $log     = $self->env->log;
    my $server  = $self->hostname;
    my $scheme  = $self->scheme // 'ldap';

    $log->debug("Creating Net::LDAP object $server");

    my $ldap    = Net::LDAP->new($server, 'scheme' => $scheme);

    unless ( $ldap ) {
        $log->error("Can not connect to LDAP $server");
        $self->can_connect(0);
        return undef;
    }
    $log->debug("Connected to LDAP $server");
    $self->can_connect(1);
    return $ldap;
}

has 'can_connect'   => (
    is          => 'rw',
    isa         => 'Bool',
);


sub get_scot_groups  {
    my $self    = shift;
    my $log     = $self->env->log;
    my $ldap    = $self->ldap;

    $log->debug("Retrieving Scot Groups");

    
    my $searchconf  = $self->group_search;
    my $search  = $ldap->search(
        'base'      => $searchconf->{base},
        'filter'    => $searchconf->{filter},
        'attrs'     => $searchconf->{attrs},
    );
    
    my @groups;

    foreach my $entry ( $search->entries ) {
        my $groupname = $entry->get_value("cn");
        $log->debug("adding group $groupname");
        push @groups, $groupname;
    }
    return \@groups;
}

sub authenticate_user {
   my $self     = shift;
   my $user     = shift;
   my $password = shift;
   my $log      = $self->env->log;

   $log->debug("attempting LDAP auth of $user");

   my $ldap    = $self->ldap;
   return 0 unless ($ldap);

   my $basedn  = $self->user_groups->{base};
   my $binddn  = 'uid='.$user.','.$basedn;


   my $msg     = $ldap->bind($binddn, 'password'   => $password);
   if($msg->is_error) {
        $log->error("$user failed LDAP auth");
       return 0;    
   }
   $log->debug("LDAP auth worked");
   return 1;
}

sub get_users_groups {
    my $self    = shift;
    my $user    = shift;
    my $log     = $self->env->log;
    my @groups  = ();
    
    my $server          = $self->hostname;
    my $binddn          = $self->dn;
    my $bindpassword    = $self->password;
    my $scheme          = $self->scheme;
    my $searchconf      = $self->user_groups;
    my $filter          = sprintf($searchconf->{filter}, $user);

    my $ldap = $self->ldap; 
    my $msg;
    eval {
       $msg     = $ldap->bind($binddn, 'password'   => $bindpassword);
    };
    if($@) {
       return -2;
    }
    if($msg->is_error) {
       return -1;    
    }
    
    my $search  = $ldap->search(
        'base'      => $searchconf->{base},
        'filter'    => $filter,
        'attrs'     => $searchconf->{attrs},
    );

    my $membership  = $search->pop_entry();
    if(defined($membership)) {    
        $log->debug("membership returned");
        foreach my $attr ( $membership->attributes() ) {
            $log->debug("attr $attr ");
            push @groups,
                map { /cn=(.*?),.*/; $1 } $membership->get_value($attr);
        }
    } else {
        return -3;
    }

    $log->trace("User $user is in the following groups: ".join(',',@groups));
    return wantarray ? @groups : \@groups;
}



1;
