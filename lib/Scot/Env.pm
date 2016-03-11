package Scot::Env;

use v5.18;
use lib '../../lib';
use strict;
use warnings;

use Log::Log4perl;
use Log::Log4perl::Layout;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;
use Time::HiRes qw(gettimeofday tv_interval);
use Module::Runtime qw(require_module compose_module_name);
use Data::Dumper;

use Meerkat;
use MooseX::Singleton;
use namespace::autoclean;

has version => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '3.5',
);

has servername => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'localhost',
);

has mojo    => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_get_mojo_defaults',
);

sub _get_mojo_defaults {
    return {
        secrets => [qw(scot1sfun sc0t1sc00l)],
        default_expiration  => 14400,
    };
}

has mode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    builder     => '_get_mode',
);

sub _get_mode {
    return $ENV{'scot_mode'} // 'prod';
}

has authmode    => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    builder     => '_get_authmode',
);

sub _get_authmode {
    return $ENV{'scot_authmode'} // 'prod';
}

has group_mode  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'ldap', # local is other option
);

has default_owner   => (
    is              => 'rw',
    isa             => 'Str',
    required        => 1,
    lazy            => 1,
    builder         => '_get_default_owner'
);

sub _get_default_owner {
    my $self    = shift;
    my $mongo   = $self->mongo;
    my $item    = $mongo->collection('Config')->find_one({
        module    => "default_owner",
    });
    if ( $item ) {
        return $item->item->{owner};
    } 
    else {
        return "scot-admin";
    }
}

has default_groups  => ( 
    is              => 'rw',
    isa             => 'HashRef',
    required        => 1,
    lazy            => 1,
    builder         => '_get_default_groups'
);

sub _get_default_groups {
    my $self    = shift;
    my $mongo   = $self->mongo;
    
    my $collection  = $mongo->collection('Config');
    my $config_obj  = $collection->find_one({
        module        => "default_groups",
    });
    if ( $config_obj ) {
        #  config is 
        # { read => [group1,...], modify => [ group1,...]}
        return $config_obj->item;
    }
    else {
        return {
            read        => [ qw(ir testing) ],
            modify      => [ qw(ir testing) ],
        };
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
);

sub _get_authtype {
    my $self    = shift;
    my $type    = $ENV{'SCOT_AUTH_TYPE'} // "Remoteuser";

    my $col     = $self->mongo->collection('Config');
    my $obj     = $col->find_one({ module => "authtype" });
    if ( $obj ) {
        return $obj->item->{type};
    }
    return $type;
}

has authclass => (
    is          => 'rw',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_get_authclass',
);

sub _get_authclass {
    my $self        = shift;
    my $authtype    = $self->authtype;
    return 'controller-auth-'.lc($authtype);
}

has mongo_config    => (
    is              => 'rw',
    isa             => 'HashRef',
    required        => 1,
    lazy            => 1,
    builder         => '_get_mongo_config',
);

sub _get_mongo_config {
    my $self    = shift;
    return {
        host            => 'mongodb://localhost',
        db_name         => 'scot-' . $self->mode,
        find_master     => 1,
        write_safety    => 1,
        #user            => 'scot',
        #pass            => 'scot1',
        port            => 27017,
    };
}

has mongo   => (
    is          => 'ro',
    isa         => 'Meerkat',
    lazy        => 1,
    required    => 1,
    builder     => '_build_mongo',
);

sub _build_mongo {
    my $self    = shift;
    my $mconf   = $self->mongo_config;
    $self->log->trace("Mongo Config: ",{ filter=>\&Dumper, value=>$mconf});
    my $mongo   = Meerkat->new(
        model_namespace         => "Scot::Model",
        collection_namespace    => "Scot::Collection",
        database_name           => $mconf->{db_name},
        client_options          => {
            host        => $mconf->{host},
            # username    => $mconf->{user},
            # passowrd    => $mconf->{pass},
            w           => $mconf->{write_safety},
            find_master => $mconf->{find_master},
            # max_time_ms => 1000,
        },
    );
    return $mongo;
}

has 'filestorage'   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/opt/scotfiles',
);

has 'log_level' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => "$TRACE",
);

has 'log'   => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_logger',
);

has 'logfile'   => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_log_file',
);

sub _get_log_file {
    my $self    = shift;
    my $logfile = $ENV{'scot_log_file'} // "/var/log/scot/scot.log";
}
    

sub _build_logger {
    my $self    = shift;
    my $mode    = $self->mode;
    my $logfile = $self->logfile;

    my $log     = Log::Log4perl->get_logger("Scot");
    my $layout  = Log::Log4perl::Layout::PatternLayout->new(
        '%d %7p [%P] %15F{1}: %4L %m%n'
    );
    my $appender    = Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::File",
        name        => "scot_log",
        filename    => $logfile,
        autoflush   => 1,
    );
    $appender->layout($layout);
    $log->add_appender($appender);
    # $log->level($TRACE);
    $log->level($self->log_level);
    return $log;
}

# move this eventually to a database configuration item
has tor_url => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'http://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=132.175.81.4',
);

sub BUILD {
    my $self    = shift;
    my $log     = $self->log;
    my $loglevel = $log->level();
    $log->level($WARN);

    $log->trace("-------------------------");
    $log->trace("Scot::Env is Initializing");
    $log->trace("-------------------------");

    my $mongo   = $self->mongo;

    my $prefix  = "";
    my $meta    = $self->meta;
    $meta->make_mutable;

    my $module_cursor   = $self->get_module_list;

    $log->trace($module_cursor->count . " Modules will be loaded");

    while ( my $module_obj = $module_cursor->next ) {

        my $module_name     = $module_obj->module;
        my $attribute_name  = $module_obj->attribute;

        #my $fullname    = compose_module_name($prefix, $module_name);
        my $fullname    = $module_name;

        $log->trace("Requiring module $fullname");
        require_module($fullname);

        $log->trace("Creating attribute $attribute_name");
        $meta->add_attribute(
            $attribute_name => (
                is  => 'rw',
                isa => $fullname,
            )
        );

        my $conf    = $self->get_module_conf($fullname);
        my $module  = $fullname->new($conf);

        if ( defined ($module) ) {
            $self->$attribute_name($module);
            $log->trace("added link to module");
        }
        else {
            $log->error("Failed to create $fullname");
        }
    }

    # build auth class
    my $atype   = $self->authtype;
    my $amodule = "Scot::Controller::Auth::$atype";
    $log->trace("Building Auth module $amodule");
    require_module($amodule);
    $self->meta->add_attribute(
        "auth_module"   => {
            is      => 'rw',
            isa     => $amodule,
        }
    );
    my $amodobj = $amodule->new;
    if ( $amodobj ) {
        $self->auth_module($amodobj);
    }
    else {
        $log->error("Failed to instantiate $amodule");
    }
    $self->load_env_config_items();
    # lock er down
    $meta->make_immutable;
    $log->level($loglevel);
}

sub load_env_config_items {
    my $self    = shift;
    my $mongo   = $self->mongo;
    my $log     = $self->log;
    my $col     = $mongo->collection('Config');
    my $cursor  = $col->find({module => "Scot::Env"});
    my $meta    = $self->meta;

    $log->debug("loading Env configuration items");
    
    while (my $confobj = $cursor->next) {
        my $item    = $confobj->item;
        foreach my $key (keys %{$item}) {
            my $type    = "Str";
            if ( ref($item->{$key}) eq "ARRAY" ) {
                $type   = "ArrayRef";
            }
            if ( ref($item->{$key}) eq "HASH" ) {
                $type   = "HashRef";
            }
            $log->debug("creating attribute $key of type $type");
            $meta->add_attribute(
                $key    => (
                    is  => 'rw',
                    isa => $type,
                )
            );
            $log->debug("setting $key to ",{filter=>\&Dumper, value=>$item->{$key}});
            $self->$key($item->{$key});
        }
    }
}

sub get_module_list {
    my $self    = shift;
    my $mongo   = $self->mongo;
    my $log     = $self->log;

    $log->trace("Looking for Scot Modules to load");

    my $collection  = $mongo->collection('Scotmod');
    my $cursor      = $collection->find({});
    return $cursor;
}

sub get_module_conf {
    my $self    = shift;
    my $class   = shift;
    my $mongo   = $self->mongo;
    
    my $collection  = $mongo->collection('Config');
    my $config_obj  = $collection->find_one({
        module       => $class,
    });
    unless ($config_obj) {
        return {};
    }
    return $config_obj->item;
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
        delete $json->{$type};
    }
    return @tags;
}

1;
