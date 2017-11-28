package Scot::Env;

use v5.18;
use strict;
use warnings;

use lib '../../lib';
#use lib '../../../lib';
#use lib '../../../Scot-Internal-Modules/lib';
#use lib '../../../../Scot-Internal-Modules/lib';

use Safe;
use Time::HiRes qw(gettimeofday tv_interval);
use Module::Runtime qw(require_module compose_module_name);
use Data::Dumper;
use Scot::Util::LoggerFactory;
use Scot::Util::Date;
use namespace::autoclean;
# use CGI::IDS;

use Moose;
use MooseX::Singleton;

has debug   => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0, # 1 = print messages, 0 = quiet
);

has date_util => (
    is          => 'ro',
    isa         => 'Scot::Util::Date',
    required    => 1,
    default     => sub { Scot::Util::Date->new; },
);

has config_file => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_config_file',
    predicate   => 'has_config_file',
);

sub _build_config_file  {
    my $self    = shift;
    my $file    = "/opt/scot/etc/scot.cfg.pl";

    print "Config file not provided!\n" if $self->debug;

    if ( $self->has_config_href ) {
        print "Config HREF provided. \n" if $self->debug;
        return ' ';
    }

    if ( defined $ENV{'scot_config_file'} ) {
        $file   = $ENV{'scot_config_file'};
        print "Using $file from environment var\n" if $self->debug;
    }
    else {
        print "Using default $file\n" if $self->debug;
    }
    return $file;
}

has config_href => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_config_href',
    predicate   => 'has_config_href',
);

sub _build_config_href {
    my $self    = shift;
    my $file    = $self->config_file; # trigger lazy
    return $self->read_config_file;
}

sub BUILD {
    my $self    = shift;
    my $meta    = $self->meta;
    my $href    = $self->config_href;

    print "BUILDING SCOT environment\n" if $self->debug;

    $meta->make_mutable;

    my $modules_aref    = delete $href->{modules};

    # load attributes in config file
    foreach my $attribute ( keys %{$href} ) {
        my $ref     = $href->{$attribute};
        my $type    = ucfirst(lc(ref($ref)))."Ref";

        if ( $type eq "Ref" ) {
            if ( $type =~ /^\d+$/ ) {
                $type   = "Int";
            }
            else {
                $type   = 'Str';
            }
        }
        print "$type Attribute $attribute = " .Dumper($ref) if $self->debug;

        $meta->add_attribute(
            $attribute  => (
                is  => 'rw',
                isa => $type,
            )
        );
        $self->$attribute($ref);
    }

    # now a log config attribute should be loaded, so let's build 
    # the logger

    print "Building Logger\n" if $self->debug;
    my $log = $self->build_logger($self->log_config);
    $meta->add_attribute( log => ( is => 'rw', isa => 'Log::Log4perl::Logger'));
    $self->log($log);
    
    # now build the modules
    foreach my $href (@{ $modules_aref }) {
        my $name    = $href->{attr};
        my $class   = $href->{class};
        my $config  = $href->{config};

        print "Building module $class\n" if $self->debug;

        unless (defined $config) {
            warn "No Config for  $class!\n";
        }

        require_module($class);

        my $instance_vars = {
            log         => $log,
            config      => $config,
            env         => $self,
        };
        my $instance    = $class->new($instance_vars);

        unless (defined $instance) {
            die "Creating $class instance FAILED!\n";
        }

        if ( $class =~ /Factory/ ) {
            my $get_method = "get_".$name;
            $instance = $instance->$get_method;
        }

        # some modules are factory types so we need to inspect what is returned
        my $module_type = ref($instance);
        print "Adding attribute $name type $module_type\n" if $self->debug;
        $meta->add_attribute( $name => ( is => 'rw', isa => $module_type ) );
        $self->$name($instance);
        # undef($instance);
    }
    $meta->make_immutable;
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

sub read_config_file {
    my $self    = shift;
    my $file    = $self->config_file;

    print "Reading $file...\n" if $self->debug;

    unless (defined $file) {
        die "Config file not set!\n";
    }

    unless (-r $file) {
        die "Config file not readable!\n";
    }
    my $href    = $self->get_config_href($file);
    print "config is: ".Dumper($href)."\n" if $self->debug;
    return $href;
}

sub get_config_href {
    my $self    = shift;
    my $file    = shift;

    no strict 'refs';
    my $container   = new Safe 'MCONFIG';
    my $result      = $container->rdo($file);
    my $hashname    = 'MCONFIG::environment';
    my %copy        = %$hashname;
    my $href        = \%copy;
    return $href;
}

sub get_config_value {
    my $self    = shift;
    my $attr    = shift;
    my $default = shift;
    my $envname = shift;

    if ( defined $envname ) {
        if ( defined $ENV{$envname} ) {
            return $ENV{$envname};
        }
    }
    
    my @path    = split(/\./, $attr); # mongo style deref
    my $initial = shift @path;
    my $ref     = $self->$initial;
    foreach my $p (@path) {
        $ref    = $ref->{$p};
    }
    if ( defined $ref ) {
        return $ref;
    }
    return $default;
}

sub build_logger {
    my $self    = shift;
    my $config  = shift;
    print "Logger config is ".Dumper($config)."\n" if $self->debug;
    my $factory = Scot::Util::LoggerFactory->new( config => $config );
    return $factory->get_logger;
}

# this helps identify the problem when SCOT wants/needs an $env->foo
# value, but the config file doesn't have the foo attribute.  Without this
# the program will blow up with a "method "foo" not found in object $env"
# 

sub get_config_item {
    my $self    = shift;
    my $name    = shift;
    my $log     = $self->log;

    $log->debug("grabbing config item $name");

    my $meta    = $self->meta;
    my $method  = $meta->get_method($name);

    if ( defined $method && ref($method) eq "Class::MOP::Class") {
        return $method->execute;
    }

    $log->error("The env obj does not have an accessor for $name");
    $log->error("...check that the config file has that attribute");

    return undef;
}

sub get_handle {
    my $self    = shift;
    my $name    = shift;
    return $self->get_config_item($name);
}

sub is_admin {
    my $self        = shift;
    my $user        = shift;
    my $groups      = shift;
    my $admin_group = $self->admin_group;
    my $log         = $self->log;

    $log->debug("Checking Admin status of $user");
    $log->debug("admin_group = $admin_group");
    $log->debug("users groups are ",{filter=>\&Dumper, value=>$groups});

    return undef if (! defined $admin_group);
    return grep { /$admin_group/ } @$groups;
}

1;
