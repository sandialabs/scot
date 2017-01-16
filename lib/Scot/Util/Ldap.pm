package Scot::Util::Ldap;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Net::LDAP;
use Try::Tiny;
use Try::Tiny::Retry ':all';
use Moose;

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { 
        {
            servername  => 'sec-ldap-nm.sandia.gov',
            scheme      => 'ldap',
            dn          => 'cn=snlldapproxy,ou=local config,dc=gov',
            password    => 'snlldapproxy',
            group_search    => {
                base    => 'ou=groups,ou=snl,dc=nnsa,dc=doe,dc=gov',
                filter  => '(| (cn=wg-scot*))',
                attrs   => [ 'cn' ],
            },
            user_groups => {
                base    => 'ou=accounts,ou=snl,dc=nnsa,dc=doe,dc=gov',
                filter  => 'uid=%s',
                attrs   => [ 'memberOf' ],
            },
        }; 
    },
);

has log     => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
);

has ldap    => (
    is          => 'ro',
    isa         => 'Net::LDAP',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ldap_cache',
    builder     => '_build_ldap_connection',
);

sub _build_ldap_connection {
    my $self    = shift;
    my $log     = $self->log;
    my $conf    = $self->config;
    my $server  = $conf->{servername} // 'localhost';
    my $scheme  = $conf->{scheme} // 'ldap';

    $log->debug("Connecting to LDAP server $server");

    my $ldap;

    retry {
        $ldap   = Net::LDAP->new($server, 'scheme' => $scheme, keepalive => 1);
        if ( ! defined $ldap ) {
            $log->error("Failed to connect to $server");
            die "connection failed";
        }
    }
    on_retry {
        $log->warn("retrying ldap connection");
    }
    delay_exp { 3, 1e5 }
    catch {
        $log->error("Failed to Connect to IMAP Server: $_");
        die "Failed to Connect to IMAP server";
    };
    return $ldap;
}

sub get_scot_groups  {
    my $self    = shift;
    my $log     = $self->log;
    my $ldap    = $self->ldap;

    $log->debug("Retrieving Scot Groups");

    
    my $searchconf    = $self->config->{group_search};
    my %searchparams  = (
            'base'   => $searchconf->{base},
            'filter' => $searchconf->{filter},
            'attrs'  => $searchconf->{attrs},
    );
    my $search;
    
    retry {
        $search = $ldap->search(%searchparams);
        if ( ! defined $search ) {
            $log->error("Search failed!", { filter=>\&Dumper, value=>\%searchparams});
            die "Search failed";
        }
    }
    on_retry {
        $log->warn("clearing ldap connection cache and retrying search");
        $self->clear_ldap_cache;
    }
    catch {
        $log->error("LDAP communication failed: $_");
        $log->error("Returning empty group list");
        return [];
    };
    
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
    my $ldap     = $self->ldap;
    my $basedn   = $self->user_groups->{base};
    my $binddn   = 'uid='.$user.','.$basedn;
    $log->debug("attempting LDAP auth of $user");

    return $self->do_bind($binddn, $password);
}

sub do_bind {
    my $self    =   shift;
    my $dn      =   shift;
    my $pass    =   shift;
    my $log     = $self->log;
    my $ldap    = $self->ldap;

    $log->debug("Attempting to bind to $dn");

    my $msg;

    retry {
        $msg    = $ldap->bind($dn, 'password' => $pass);
        if ( $msg->is_error ) {
            $log->error("Bind Error: ".$msg->errorMessage);
            die "bind error";
        }
    }
    delay_exp { 3, 1e5 }
    on_retry {
        $log->warn("clearing ldap connection and retrying bind");
        $self->clear_ldap_cache;
    }
    catch {
        $log->error("Failed to bind for $dn");
        return 0;
    };
    return 1;
}



sub get_users_groups {
    my $self    = shift;
    my $user    = shift;
    my $log     = $self->log;
    my $conf    = $self->config;
    my $ldap    = $self->ldap; 
    my @groups  = ();
    
    my $server          = $conf->{hostname};
    my $binddn          = $conf->{dn};
    my $bindpassword    = $conf->{password};
    my $scheme          = $conf->{scheme};
    my $searchconf      = $conf->{user_groups};
    my $filter          = sprintf($searchconf->{filter}, $user);

    my $loglevel    = $log->level;
    # turn debug off unless needed
    $log->level(Log::Log4perl::Level::to_priority('DEBUG')); 

    $log->debug("ldap group filter is ", { filter=>\&Dumper, value=>$filter});
    $log->debug("ldap binddn is ", { filter=>\&Dumper, value=>$binddn});

    unless ( $self->do_bind($binddn, $bindpassword) ) {
        return -1;
    }
    
    my $search;
    
    retry {
        $search = $ldap->search(
            'base'      => $searchconf->{base},
            'filter'    => $filter,
            'attrs'     => $searchconf->{attrs},
        );
        unless ( defined $search ) {
            $log->error("Search failed!");
            die "search failed";
        }
    }
    on_retry {
        $log->warn("clearing ldap cache and retrying search");
        $self->clear_ldap_cache;
    }
    catch {
        $log->error("Search for user groups failed!");
        return -3;
    };

    my $membership  = $search->pop_entry();

    if(defined($membership)) {    
        $log->debug("membership returned");
        foreach my $attr ( $membership->attributes() ) {
            $log->debug("attr $attr ");
            push @groups,
                map { /cn=(.*?),.*/; $1 } $membership->get_value($attr);
        }
    } else {
        $log->error("get users groups from ldap returned nothing!");
        return -3;
    }
    $log->level($loglevel); # restore the loglevel from the rest of the app

    $log->trace("User $user is in the following groups: ".join(',',@groups));
    return wantarray ? @groups : \@groups;
}



1;
