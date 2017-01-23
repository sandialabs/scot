package Scot::Env;

use v5.18;
use strict;
use warnings;

use lib '../../lib';
#use lib '../../../lib';
#use lib '../../../Scot-Internal-Modules/lib';
#use lib '../../../../Scot-Internal-Modules/lib';

use Time::HiRes qw(gettimeofday tv_interval);
use Module::Runtime qw(require_module compose_module_name);
use Data::Dumper;
use Scot::Util::LoggerFactory;
use namespace::autoclean;

use Moose;
use MooseX::Singleton;

with qw(Scot::Role::Configurable);

# for debugging
#around BUILDARGS => sub {
#    my $orig    = shift;
#    my $class   = shift;
#
#    print "$class $orig ".Dumper(@_)."\n";
#    foreach my $k (keys %ENV) {
#        next unless ($k =~ /scot/);
#        print "$k = $ENV{$k}\n";
#    }
#
#    return $class->$orig(@_);
#};

has version => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_version',
);

sub _build_version {
    my $self    = shift;
    my $attr    = 'version';
    my $default = '3.5.1';
    return $self->get_config_value($attr,$default);
}


has servername => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_servername',
    predicate   => 'has_servername',
);

sub _build_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "scot";
    return $self->get_config_value($attr,$default);
}

has mojo_defaults    => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy        => 1,
    required    => 1,
    builder     => '_build_mojo_defaults',
    predicate   => 'has_mojo_defaults',
);

sub _build_mojo_defaults {
    my $self    = shift;
    my $attr    = "mojo_defaults";
    my $default = {
        secrets => [ qw(scot1sfun sc0t1sc00l) ],
        default_expiration  => 14400,
    };
    return $self->get_config_value($attr,$default);
}

has mode    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_mode',
    predicate   => 'has_mode',
);

sub _build_mode {
    my $self    = shift;
    my $attr    = "mode";
    my $default = "prod";
    return $self->get_config_value($attr,$default);
}

has group_mode    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_group_mode',
    predicate   => 'has_group_mode',
);

sub _build_group_mode {
    my $self    = shift;
    my $attr    = "mode";
    my $default = "Local";
    return $self->get_config_value($attr,$default);
}

has default_owner    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    lazy            => 1,
    builder         => '_build_default_owner',
    predicate       => 'has_default_owner',
);

sub _build_default_owner {
    my $self    = shift;
    my $attr    = "default_owner";
    my $default = "scot-admin";
    return $self->get_config_value($attr,$default);
}

has default_groups    => (
    is              => 'ro',
    isa             => 'HashRef',
    required        => 1,
    lazy            => 1,
    builder         => '_build_default_groups',
    predicate       => 'has_default_groups',
);

sub _build_default_groups {
    my $self    = shift;
    my $attr    = "default_groups";
    my $default = { 
        read    => [qw(wg-scot-ir)],
        modify  => [qw(wg-scot-ir)],

    };
    return $self->get_config_value($attr,$default);
}

has admin_group    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    lazy            => 1,
    builder         => '_build_admin_group',
    predicate       => 'has_admin_group',
);

sub _build_admin_group {
    my $self    = shift;
    my $attr    = "admin_group";
    my $default = "wg-scot-admin";
    return $self->get_config_value($attr,$default);
}

has auth_type    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_auth_type',
    predicate   => 'has_auth_type',
);

sub _build_auth_type {
    my $self    = shift;
    my $attr    = "auth_type";
    my $default = "Local";
    return $self->get_config_value($attr,$default);
}

has authclass    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_authclass',
    predicate   => 'has_authclass',
);

sub _build_authclass {
    my $self    = shift;
    my $attr    = "authclass";
    my $default = "controller-auth-".lc($self->auth_type);
    return $self->get_config_value($attr,$default);
}

has file_store_root     => (
    is                  => 'ro',
    isa                 => 'Str',
    lazy                => 1,
    required            => 1,
    builder             => '_build_file_store_root',
);

sub _build_file_store_root {
    my $self    = shift;
    my $attr    = "file_store_root";
    my $default = "/opt/scotfiles";
    return $self->get_config_value($attr,$default);
}

has modules =>  (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy        => 1,
    required    => 1,
    builder     => '_build_modules',
);

sub _build_modules {
    my $self    = shift;
    my $attr    = "modules";
    my $default = [
        {
            attr    => "mongoquerymaker",
            class   => "Scot::Util::MongoQueryMaker",
            config  => "",
        },
        {
            attr    => "imap",
            class   => "Scot::Util::Imap",
            config  => "imap.cfg",
        },
        {
            attr    => "enrichments",
            class   => "Scot::Util::Enrichments",
            config  => "enrichments.cfg",
        },
        {
            attr    => "mongo",
            class   => "Scot::Util::Mongo",
            config  => "mongo.cfg",
        },
        {
            attr    => "log",
            class   => "Scot::Util::LoggerFactory",
            config  => "logger.cfg",
        },
        {
            attr    => "ldap",
            class   => "Scot::Util::Ldap",
            config  => "ldap.cfg",
        },
        {
            attr    => "es",
            class   => "Scot::Util::ESProxy",
            config  => "es.cfg",
        },
    ];
    return $self->get_config_value($attr,$default);
}

has config_paths => (
    is              => 'ro',
    isa             => 'ArrayRef',
    lazy            => 1,
    required        => 1,
    builder         => '_build_config_paths',
);

sub _build_config_paths {
    my $self    = shift;
    my $attr    = "config_paths";
    my $default = [qw(/opt/scot/etc)];

    print "building config_paths\n";

    return $self->get_config_value($attr,$default);
}

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    lazy        => 1,
    required    => 1,
    builder     => '_build_log',
    predicate   => 'has_log',
);

sub _build_log {
    my $self    = shift;
    my $attr    = "log_config";
    my $default = "/opt/scot/etc/log.cfg";
    my $cfile   = $self->get_config_value($attr, $default);
    my $logfactory = Scot::Util::LoggerFactory->new(
        config_file => $cfile,
        paths       => $self->config_paths,
    );
    return $logfactory->get_logger;
}


sub BUILD {
    my $self    = shift;

    print "loading ENV config from ".$self->config_file."\n";
    print "   in path: ". join(":", @{$self->paths})."\n";
    my $config  = $self->config; # force the lazy to do the work
    my $modules = $self->modules;
    my $meta    = $self->meta;
    my $log     = $self->log;
    $meta->make_mutable;

    $log->debug("Env.pm is building Util Modules");

    my $paths = $self->config_paths;

    foreach my $href (@{ $modules }) {
        my $name    = $href->{attr};
        my $class   = $href->{class};
        my $config  = $href->{config};

        # print "===================\n";
        # print "Building Module...\n";
        # print "\tmodule = $name\n";
        # print "\tclass  = $class\n";
        # print "\tfile   = $config\n";
        # print "\tpaths  = ".Dumper($paths)."\n";
        # print "\n";

        $log->debug("creating attribute $name as $class from $config");

        # print "requireing $class\n";
        require_module($class);
        # print "instantiating $class\n";
        my $instance_vars = {
            paths       => $self->config_paths,
            log         => $log,
            config_file => $config,
        };

        $log->debug("instance_vars = ", 
                    {filter=>\&Dumper, value=>$instance_vars});

        my $instance    = $class->new($instance_vars);
        # print "instantiated\n";

        unless (defined $instance) {
            die "Creating $class instance FAILED!\n";
        }

        if ( $class =~ /Factory/ ) {
            my $get_method = "get_".$name;
            $instance = $instance->$get_method;
        }

        # some modules are factory types so we need to inspect what is returned
        my $module_type = ref($instance);

        $meta->add_attribute( $name => ( is => 'rw', isa => $module_type ) );
        $self->$name($instance);

#         print "\t...$module_type built\n";
        undef($instance);
    }
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
        if ( $self->auth_type eq "testing" ) {
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
1;
