package Scot::Env;

use v5.18;
use lib '../../lib';
use lib '../../../Scot-Internal-Modules/lib';
use strict;
use warnings;

use Time::HiRes qw(gettimeofday tv_interval);
use Module::Runtime qw(require_module compose_module_name);
use Data::Dumper;
use File::Find;
use Safe;
use namespace::autoclean;

use Moose;
use MooseX::Singleton;

has version => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    default     => '3.5',
);

has configfile  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_get_configfile',
);

sub _get_configfile {
    my $self    = shift;
    if ( $ENV{'scot_env_configfile'} ) {
        return $ENV{'scot_env_configfile'};
    }
    return '/opt/scot/etc/scot_env.cfg';
}

has config      => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    traits      => ['Hash'],
    builder     => '_get_environment_config',
);

sub _get_environment_config {
    my $self    = shift;
    my $file    = $self->configfile;

    unless ( $file ) {
        die "configfile NOT SET!";
    }
    unless ( -e $file ) {
        die "configfile $file does not exist!";
    }

    no strict 'refs'; # I know, this smells, but...
    my $container   = new Safe 'CONFIG';
    my $ret         = $container->rdo($file);
    my $hname       = "CONFIG::environment";
    my $href        = \%$hname;

    return $href;
}

# mainly for testing
has cachedconfigs => (
    is          => 'rw',
    isa         => 'HashRef',
);

has servername => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    predicate   => 'has_servername',
    builder     => '_get_servername',
);

sub _get_servername {
    my $self    = shift;
    return $self->config->{servername};
}

has mojo    => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_get_mojo_defaults',
    predicate   => 'has_mojo',
);

sub _get_mojo_defaults {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{mojo_defaults};
}

has mode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_mode',
    predicate   => 'has_mode',
);

sub _get_mode {
    my $self    = shift;
    # Env then Config then default
    my $mode    = $self->config->{mode};
    if ( $ENV{'scot_mode'} ) {
        $mode   = $ENV{'scot_mode'};
    }
    unless ($mode) {
        $mode   = 'prod';
    }
    return $mode;
}

has authmode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_authmode',
    predicate   => 'has_authmode',
);

sub _get_authmode {
    return $ENV{'scot_authmode'} // 'prod';
}

has group_mode  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    predicate   => 'has_group_mode',
    builder     => '_get_group_mode',
);

sub _get_group_mode {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{group_mode};
}

has default_owner   => (
    is              => 'rw',
    isa             => 'Str',
    required        => 1,
    lazy            => 1,
    builder         => '_get_default_owner',
    predicate       => 'has_default_owner',
);

sub _get_default_owner {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{default_owner} // "scot-admin";
}

has default_groups  => ( 
    is              => 'rw',
    isa             => 'HashRef',
    required        => 1,
    lazy            => 1,
    builder         => '_get_default_groups',
    predicate       => 'has_default_groups',
);

sub _get_default_groups {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{default_groups};
    
}

has admin_group => (
    is                  => 'rw',
    isa                 => 'Str',
    required            => 1,
    lazy                => 1,
    builder             => '_get_admin_group',
    predicate           => 'has_admin_group',
);

sub _get_admin_group {
    my $self    = shift;
    my $item    = $self->config->{admin_group};
    if ( $item ) {
        return $item;
    } 
    else {
        return "wg-scot-admin";
    }
}

sub get_test_groups {
    return [ qw(wg-scot-ir) ];
}

has authtype    => (
    is              => 'rw',
    isa             => 'Str',
    lazy            => 1,
    required        => 1,
    builder         => '_get_authtype',
    predicate       => 'has_authtype',
);

sub _get_authtype {
    my $self    = shift;
    # ENV then Config then default
    my $type    = $ENV{'SCOT_AUTH_TYPE'};

    if ( $type ) {
        return $type;
    }

    $type = $self->config->{authentication_type};

    if ( $type) { 
        return $type;
    }

    return 'RemoteUser';

}

has authclass => (
    is          => 'rw',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_get_authclass',
    predicate   => 'has_authclass',
);

sub _get_authclass {
    my $self        = shift;
    my $authtype    = $self->authtype;
    return 'controller-auth-'.lc($authtype);
}

has 'filestorage'   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    predicate   => 'has_filestorage',
    builder     => '_get_filestorage',
);

sub _get_filestorage {
    my $self    = shift;
    return $self->config->{file_store_root};
}

sub BUILD {
    my $self    = shift;
    my $conf    = $self->config;
    my $paths   = $conf->{config_path};
    my $meta    = $self->meta;
    $meta->make_mutable;

    # first build Logger
    my $logmodule       = delete $conf->{modules}->{log}; # delete it so we don't repeat building later
    my $logconfigfile   = $conf->{configs}->{log};
    my $logconfig       = $self->get_config('log', $logconfigfile);

    # say Dumper($logconfig);

    require_module($logmodule);
    my $log             = $logmodule->new($logconfig);
    
    $meta->add_attribute(
        'log'   => ( 
            is      => 'rw',
            isa     => 'Log::Log4perl::Logger',
        )
    );
    $self->log($log);

    $log->debug("Starting Env.pm");

    my %cacheconfs;

    foreach my $name (keys %{$conf->{modules}} ) {
        $log->debug("Creating attribute $name");
        my $class           = $conf->{modules}->{$name};
        my $configfile      = $conf->{configs}->{$name};
        my $confhref        = $self->get_config($name, $configfile);
        $cacheconfs{$name}  = $confhref;
        $confhref->{log}    = $log;
        require_module($class);
        my $instance    = $class->new($confhref);
        unless ( $instance ) {
            die "Creating $class instance Failed!";
        }
        my $ctype       = ref($instance); # some these may be factories returning a different type
        
        $meta->add_attribute(
            $name   => (
                is      => 'rw',
                isa     => $ctype,
            )
        );
        $self->$name($instance);
    }
    $self->cachedconfigs(\%cacheconfs);
}

sub get_config {
    my $self    = shift;
    my $name    = shift;
    my $file    = shift;
    my $conf    = $self->config;
    my $paths   = $conf->{config_path};
    my $fqname;
    find(sub {
        if ( $_ eq $file ) {
            $fqname = $File::Find::name;
            return;
        }
    }, @$paths);

    no strict 'refs'; # I know, but...
    my $cont    = new Safe 'MCONFIG';
    my $r       = $cont->rdo($fqname);
    my $hname   = 'MCONFIG::environment';
    my %copy    = %$hname;
    my $href    = \%copy;

    # say "loaded $name config: ", Dumper($href);

    return $href;
}

=item C<get_timer(I<$title>)>

return a code ref (closure) that measures the time between calls

my $timer = $env->timer("foo")
...later...
my $elapsed_seconds = &$timer;

 who says perl can't do cool things.  

=cut

sub get_timer {
    my $self    = shift;
    my $title   = shift;
    my $start   = [ gettimeofday ];
    my $log     = $self->log;

    # $log->debug("Setting Timer for $title");

    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [ gettimeofday ]);
        $log->debug("$title Elapsed Time: $elapsed");
        return $elapsed;
    };
}

sub now {
    return time();
}

sub get_user {
    my $self    = shift;
    my $api     = shift;
    my $user    = $api->session('user');

    unless ( defined $user ) {
        if ( $self->authmode eq "test" ) {
            $self->log->debug("In authmod of test, setting username to test");
            $user   = "test";
        }
        else {
            my $msg = "Error: Owner not provided by session variable, did you log in?";
            $self->log->error($msg);
            return undef;
        }
    }
    return $user;
}

sub get_epoch_cols {
    my $self    = shift;
    my @cols    = qw(
        when
        updated
        created
        occurred
    );
    return wantarray ? @cols : \@cols;
}

sub get_int_cols {
    my $self    = shift;
    my @cols    = qw(
        views
    );
    return wantarray ? @cols : \@cols;
}

sub get_req_array {
    my $self    = shift;
    my $json    = shift;
    my $type    = shift;
    my @tags    = ();

    if ( defined $json->{$type} ) {
        push @tags, @{$json->{$type}};
    }
    return @tags;
}

sub get_config_item {
    my $self        = shift;
    my $module      = shift;
    my $attribute   = shift;
    my $mongo       = $self->mongo;
    my $col         = $mongo->collection('Config');
    my $obj         = $col->find_one({ module => $module });
    my $item        = $obj->item;
    return $item->{$attribute};
}

1;
