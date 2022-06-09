package Scot::Util::Ldap;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use Net::LDAP;
use Try::Tiny;
use Try::Tiny::Retry ':all';

use Moose;
extends 'Scot::Util';

has servername    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_servername',
);

sub _build_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "localhost";
    return $self->get_config_value($attr,$default);
}

has dn          => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_dn',
);

sub _build_dn {
    my $self    = shift;
    my $attr    = "dn";
    my $default = "cn=cname,ou=ouname config,dc=dcname";
    return $self->get_config_value($attr, $default);
}

has password    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_password',
);

sub _build_password {
    my $self    = shift;
    my $attr    = "password";
    my $default = "changemenow";
    return $self->get_config_value($attr, $default);
}

has scheme      => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_scheme',
);

sub _build_scheme {
    my $self    = shift;
    my $attr    = "scheme";
    my $default = "ldap";
    return $self->get_config_value($attr, $default);
}

has group_search      => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy        => 1,
    required    => 1,
    builder     => '_build_group_search',
);

sub _build_group_search {
    my $self    = shift;
    my $attr    = "group_search";
    my $default = {
        base    => 'ou=groups,ou=ouname,dc=dcname1,dc=dcname2,dc=dcname3',
        filter  => '(| (cn=wg-scot*))',
        attrs   => [ 'cn' ],
    };
    return $self->get_config_value($attr, $default);
}

has user_groups      => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy        => 1,
    required    => 1,
    builder     => '_build_user_groups',
);

sub _build_user_groups {
    my $self    = shift;
    my $attr    = "user_groups";
    my $default = {
        base    => 'ou=accounts,ou=ouname,dc=dcname1,dc=dcname2,dc=dcname3',
        filter  => 'uid=%s',
        attrs   => [ 'memberOf' ],
    };
    return $self->get_config_value($attr, $default);
}

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
    my $server  = $self->servername;
    my $scheme  = $self->scheme;

    $log->trace("Connecting to LDAP server $server");

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
        $log->error("Failed to Connect to LDAP Server: $_");
        die "Failed to Connect to LDAP server";
    };
    return $ldap;
}

sub get_scot_groups  {
    my $self    = shift;
    my $log     = $self->log;
    my $ldap    = $self->ldap;

    $log->debug("Retrieving Scot Groups");

    
    my $searchconf    = $self->group_search;
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
    my $self    = shift;
    my $dn      = shift;
    my $pass    = shift;
    my $log     = $self->log;
    my $ldap    = $self->ldap;

    $log->trace("attempting bind to $dn");

    my $msg;
    my $success = 0;

    retry {
        $msg    = $ldap->bind($dn, 'password' => $pass);
        if ( ! defined $msg ) {
            $log->error("LDAP failed to return message");
            die "undefined ldap response";
        }
        if ( $msg->is_error ) {
            $log->error("Bind Error: ".$msg->error_desc);
            die $msg->error_text;
        }
        $success++;
    }
    delay_exp { 3, 1e5 }
    on_retry {
        $log->warn("reconnecting to ldap server and retrying bind");
        $self->clear_ldap_cache;
    }
    catch {
        $log->error("BIND Failed: $_");
        $success = 0;
    };
    return $success;
}

sub get_users_groups {
    my $self    = shift;
    my $user    = shift;
    my $log     = $self->log;
    my $ldap    = $self->ldap; 
    my @groups  = ();

    $log->trace("Attempting to find user $user groups");
    
    my $server          = $self->servername;
    my $binddn          = $self->dn;
    my $bindpassword    = $self->password;
    my $scheme          = $self->scheme;
    my $searchconf      = $self->user_groups;
    my $filter          = sprintf($searchconf->{filter}, $user);

    my $loglevel    = $log->level;
    # turn debug off unless needed
    $log->level(Log::Log4perl::Level::to_priority('DEBUG')); 

    $log->trace("ldap group filter is ", { filter=>\&Dumper, value=>$filter});
    $log->trace("ldap binddn is ", { filter=>\&Dumper, value=>$binddn});

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
        $log->trace("membership returned");
        foreach my $attr ( $membership->attributes() ) {
            $log->trace("attr $attr ");
            push @groups,
                grep { /scot/i }            # only care about scot groups
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
