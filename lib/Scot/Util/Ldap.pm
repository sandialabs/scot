package Scot::Util::Ldap;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Net::LDAP;
use Moose;

has config      => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

has 'log'       => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
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
    my $conf    = $self->config->{ldap};
    $self->log->debug("config is ".Dumper($conf));
    my $server  = $conf->{hostname};
    my $scheme  = $conf->{scheme} // 'ldap';

    $self->log->debug("Creating Net::LDAP object $server");

    my $ldap    = Net::LDAP->new($server, 'scheme' => $scheme);

    unless ( $ldap ) {
        $self->log->error("Can not connect to LDAP $server");
        $self->can_connect(0);
        return undef;
    }
    $self->log->debug("Connected to LDAP $server");
    $self->can_connect(1);
    return $ldap;
}

has 'can_connect'   => (
    is          => 'rw',
    isa         => 'Bool',
);

=item del

sub connect {
    my $self    = shift;
    my $user    = shift;
    my $pass    = shift;
    my $config  = $self->config;
    my $log     = $self->log;
    my $ldapconf= $config->{ldap};
    my $server  = $ldapconf->{hostname};
    my $dn      = 'uid='.$user.$ldapconf->{dn};
    my $scheme  = $ldapconf->{scheme}   // 'ldap';

    $log->debug("Connecting to LDAP $server with $scheme");

    my $ldap    = Net::LDAP->new($server, 'scheme' => $scheme);
    $log->debug("Binding to $dn");
    my $msg     = $ldap->bind($dn, 'password'   => $pass);
    if($msg->is_error) {
       return -1;    
    }
    return $ldap;
}

=cut

sub is_configured {
  my $self     = shift;
  my $log      = $self->log;
  my $config   = $self->config;

  $log->debug("Config is ", { filter => \&Dumper, value => $config->{ldap} });

  return defined($config->{ldap}->{configured});
}

sub is_disabled {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{ldap}->{is_disabled};
}

sub get_scot_groups  {
    my $self    = shift;
    my $log     = $self->log;
    my $ldap    = $self->ldap;

    $log->debug("Retrieving Scot Groups");

    my $configbase  = $self->config;
    my $config      = $configbase->{ldap};
    
    my $searchconf  = $config->{searches}->{scot_groups};
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
   my $log      = $self->log;
   my $config   = $self->config;

   $log->debug("attempting LDAP auth of $user");

   my $ldap    = $self->ldap;
   return 0 unless ($ldap);

   my $ldapconf= $config->{ldap};
   my $basedn  = $ldapconf->{searches}->{users_groups}->{base};
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
    my $log     = $self->log;
    my @groups  = ();
    
    my $config          = $self->config;
    my $ldapconf        = $config->{ldap};
    my $server          = $ldapconf->{hostname};
    my $binddn          = $ldapconf->{dn};
    my $bindpassword    = $ldapconf->{password};
    my $scheme          = $ldapconf->{scheme};
    my $searchconf      = $ldapconf->{searches}->{users_groups};
    my $filter          = sprintf($searchconf->{filter}, $user);

   # $log->debug( "Getting user groups ".
   #             "\n"." "x55 . "server  ='$server' ".
   #             "\n"." "x55 . "scheme  ='$scheme' ".
   #             "\n"." "x55 . "binddn  ='$binddn' ".
   #             "\n"." "x55 . "password='$bindpassword' ".
   #             "\n"." "x55 . "user    ='$user' ".
   #             "\n"." "x55 . "attrs   ='".join(',',@$searchconf->{attrs})."'" .  
   #             "\n"." "x55 . "filter='$filter'");

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
    return \@groups;
}



1;
