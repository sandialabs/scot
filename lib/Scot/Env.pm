package Scot::Env;

=head1 Scot::Env

OPEN SOURCE Version.

this module is glue to hold SCOT together.
Bots can include this to get the entire scot environment
Mojolicious controllers can include this to do the same
This will replace a bunch of helpers in Scot.pm and
the Tasker.pm module.

=cut

use lib '../lib';
use lib '../../lib';
use strict;
use warnings;
use v5.10;

use File::Slurp;
use Time::HiRes qw(gettimeofday tv_interval);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Layout;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;
use JSON;
use Data::Dumper;
use Config::Auto;
use DateTime;

use Scot::Types;
use Scot::Util::ActiveMQ;
use Scot::Util::Mongo;
use Scot::Util::Redis3;
use Scot::Util::Aaa;
use Scot::Util::Imap;
use Scot::Util::Ldap;
use Scot::Util::EntityExtractor;
# use Scot::Util::Sep;

use namespace::autoclean;
use Moose;

=head2 Attributes

=over 4

=item C<config_file>

the full path to the SCOT config file. (perl format)

=cut

has 'config_file'   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => "../../scot.conf",
);

=item C<config>

the parsed hash ref generated from the config_file

=cut

has 'config'    => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    lazy        => 1,
    builder     => '_parse_config_file',
);

sub _parse_config_file {
    my $self        = shift;
    my $filename    = $self->config_file;

    if ( $filename =~ /\.json$/ ) {
        my $json        = JSON->new->relaxed(1);
        my $contents    = read_file($filename);
        return $json->decode($contents);
    }
    my $conf = Config::Auto::parse($filename, format => 'perl');
    return $conf;
}

=item C<mode>

SCOT can run in various modes which controls what databases, etc.
it accesses.

=cut

has 'mode'      => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_mode',
);

sub _get_mode {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{mode};
}

=item C<interactive>

for bots, do we want interactivity?

=cut

has 'interactive'   => (
    is          => 'rw',
    isa         => 'Bool',
    traits      => [ 'Bool' ],
    required    => 1,
    default     => 0,
);

=item C<log>

reference to the Scot logging object;

=cut

has 'log'  => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_logger',
);

sub _build_logger {
    my $self    = shift;
    my $conf    = $self->config;
    my $mode    = $self->mode;
    my $logfile = $conf->{$mode}->{logfile};

    my $log     = Log::Log4perl->get_logger("Scot");
    my $layout  = Log::Log4perl::Layout::PatternLayout->new(
        '%d [%P] %15F{1}: %4L %m%n'
    );
    my $appender    = Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::File",
        name        => "scot_log",
        filename    => $logfile,
        autoflush   => 1,
    );
    $appender->layout($layout);
    $log->add_appender($appender);
    $log->level($DEBUG);

    return $log;
}


=item C<mongo>

The link to the Scot::Util::Mongo object that talks to SCOT's datastore

=cut

has 'mongo' => (
    is          => 'ro',
    isa         => 'Scot::Util::Mongo',
    lazy        => 1,
    required    => 1,
    builder     => '_build_mongo',
);

sub _build_mongo {
    my $self    = shift;
    my $config  = $self->config;
    my $mode    = $self->mode;
    my $mongo   = Scot::Util::Mongo->new(
        'log'       => $self->log,
        'config'    => $config->{$mode},
    );
    return $mongo;
}

=item C<phantom>

link to Scot::Util::Phantom

=cut

has 'phantom'   => (
    is          => 'ro',
    isa         => 'Scot::Util::Phantom',
    required    => 1,
    lazy        => 1,
    builder     => '_build_phantom',
);

sub _build_phantom {
    my $self    = shift;
    my $conf    = $self->config;
    my $mode    = $self->mode;
    my $phantom = Scot::Util::Phantom->new(
        'log'       => $self->log,
        'config'    => $conf->{$mode},
    );
    return $phantom;
}

=item C<activemq>

the activemq helper object.  sends updates to all stomp clients

=cut

has 'activemq'  => (
    is          => 'ro',
    isa         => 'Scot::Util::ActiveMQ',
    required    => 1,
    lazy        => 1,
    builder     => '_build_activemq',
);

sub _build_activemq {
    my $self    = shift;
    my $log     = $self->log;
    my $config  = $self->config;
    my $mode    = $self->mode;

    my $amq     = Scot::Util::ActiveMQ->new({
        config  => $config->{$mode},
        'log'   => $log,
    });
    return $amq;
}

=item C<redis>

link to the redis helper object

=cut

has 'redis' => (
    is          => 'ro',
    isa         => 'Scot::Util::Redis3',
    required    => 1,
    builder     => '_build_redis',
    lazy        => 1,
);

sub _build_redis {
    my $self    = shift;
    my $config  = $self->config;
    my $log     = $self->log;
    my $mode    = $self->mode;
    my $redis   = Scot::Util::Redis3->new({
        config  => $config->{$mode},
        'log'   => $log,
    });
    return $redis;
}

=item C<ldap>

The ldap attribute holds a reference to a Scot::Util::Ldap object.
Not always needed.  going to make this lazy, so should instantiate unless needed.
Might want to profile this behavior though to be sure.

=cut

has ldap        => (
    is          => 'rw',
    isa         => 'Scot::Util::Ldap',
    required    => 1,
    lazy        => 1,
    builder     => '_build_ldap',
);

sub _build_ldap {
    my $self    = shift;
    my $config  = $self->config;
    my $mode    = $self->mode;
    my $ldap    = Scot::Util::Ldap->new({
        config  => $config->{$mode},
        log     => $self->log,
    });
    return $ldap;
}


=item C<test_clock>

this attribute allows us to control timing in test scenarios

=cut

has test_clock  => (
    is          => 'rw',
    isa         => 'Epoch',
    required    => 1,
    coerce      => 1,
    builder     => '_init_test_clock',
);

sub _init_test_clock {
    my $self    = shift;
    return time();  # if not set use current time
}

=item C<imap>

link to the Scot::Util::Imap helper object

=cut

has 'imap'  => (
    is          => 'ro',
    isa         => 'Scot::Util::Imap',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imap',
);

sub _build_imap {
    my $self    = shift;
    my $config  = $self->config;
    my $mode    = $self->mode;
    my $user    = $config->{$mode}->{imap}->{username};
    my $account = $config->{email_accounts}->{$user};
    my $mongo   = $self->mongo;
    my $imap    = Scot::Util::Imap->new(
        config      => $config->{$mode},
        log         => $self->log,
        email_acct  => $account,
        mongo       => $mongo,
        env         => $self,
    );
    return $imap;
}

=item C<geoip>

link to the Scot::Util::Geoip helper object

=cut

has 'geoip' => (
    is          => 'ro',
    isa         => 'Scot::Util::Geoip',
    required    => 1,
    lazy        => 1,
    builder     => '_build_geoip',
);

sub _build_geoip {
    my $self    = shift;
    my $config  = $self->config;
    my $mode    = $self->mode;
    my $geo     = Scot::Util::Geoip->new(
        config  => $config->{$mode},
        log     => $self->log,
    );
    return $geo;
}


=item C<entity_extractor>

experimental replacement of phantomjs

=cut

has 'entity_extractor'      => (
    is          => 'rw',
    isa         => 'Scot::Util::EntityExtractor',
    required    => 1,
    lazy        => 1,
    builder     => '_get_entity_extractor',
);

sub _get_entity_extractor {
    my $self    = shift;
    my $config  = $self->config;
    my $extractor   = Scot::Util::EntityExtractor->new({
        suffixfile  => "../../etc/effective_tld_names.dat",
        log         => $self->log,
    });
    return $extractor;
}


=back

=head2 Methods

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

    $log->debug("Setting Timer for $title");

    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [ gettimeofday ]);
        $log->debug("====\n".
        " "x56 ."==== Timer   : $title\n".
        " "x56 ."==== Elapsed : $elapsed\n".
        " "x56 ."===="
        );
        return $elapsed;
    };
}

=item C<set_test_clock(I<$dt>)>

pass the same params that you would to create a DateTime object
and this will set the test_clock to that number of seconds since the epoch

=cut

sub set_test_clock {
    my $self    = shift;
    my $dt      = DateTime->new(@_);
    $self->test_clock($dt->epoch);
}

=item C<advance_test_clock(I<$unit,$quantity>)>

advance the test clock by $quantity $units of time

=cut

sub advance_test_clock {
    my $self        = shift;
    my $unit        = shift;
    my $quantity    = shift;
    my $test_clcok  = $self->test_clock;
    my $multiplier  = 1;

    $multiplier = (60*60*24)    if ($unit =~ /day/i);
    $multiplier = (60*60)       if ($unit =~ /hour/i);
    $multiplier = 60            if ($unit =~ /minute/i);

    my $seconds_to_advance  = $quantity * $multiplier;
    my $test_now            = $self->test_clock;
    $self->test_clock($test_now + $seconds_to_advance);
}

=item C<now>

return the current time in seconds since the epoch.  In test mode,
return the epoch time according to the test_clock

=cut

sub now {
    my $self    = shift;

    if ( $self->config->{use_test_clock} ) {
        $self->logger->debug("USING TEST CLOCK");
        return $self->test_clock;
    }
    return time();
}

=item C<fmt_time>

convert seconds epoch to the users timezone

=cut

sub fmt_time {
    my $self    = shift;
    my $secs    = shift;
    my $utz     = $self->session('tz') // 'UTC';
    my $tz      = shift // $utz;

    return '' unless $secs;

    my $dt  = DateTime->from_epoch(epoch=>$secs);
    $dt->set_time_zone($tz);

    return sprintf("%s", $dt);
}

=item C<deplural>

english is fun and non logical.  take stuff like vulnerabilities and return
vulnerability.

=cut

sub deplural {
    my $self    = shift;
    my $plural  = shift;
    my $singular;

    if ( $plural =~ /ies$/ ) {
        $singular   = substr($plural,0,-3) . "y";
    }
    elsif ( $plural =~ /es$/ ) {
        $singular   = substr($plural,0,-2);
    }
    elsif ( $plural =~ /s$/ ) {
        $singular   = substr($plural,0,-1);
    }
    else {
        # not dealing with fungus, and other non standards
        $singular   = $plural; # punt
    }
    return $singular;
}

=item C<get_model_class_from_collection>

give it a collection and get the Scot::Model::Class

Here's the rule:
    Collection names are plural and all lowercase
    the corresponding model is Ucfirst and singular

=cut

sub get_model_class {
    my $self        = shift;
    my $collection  = shift;
    my $colname     = ucfirst($self->deplural($collection));
    my $class       = "Scot::Model::$colname";
    return $class;
}

=item C<update_activity_log(I<$href>)>

this function allows you to update the audits collection in
a consistent way.   The href is expected to contain:
{
    data    => {
        target_type => $a,
        target_id   => $b,
        is_task     => $c,
        type        => $d,
        original_obj    => $obj1,
    }

=cut

sub update_activity_log {
    my $self    = shift;
    my $href    = shift;
    my $mongo   = $self->mongo;
    my $log     = $self->log;

    $log->trace(" - Updating Activity Log - ");

    my $audit_obj   = Scot::Model::Audit->new($href);
    my $audit_id    = $mongo->create_document($audit_obj);

    if ($audit_id) {

        $self->send_amq_message($href);

    }
    else {
        $log->error("Failed to create audit entry from ".Dumper($href));
        return undef;
    }
    return 1;
}

sub send_amq_message {
    my $self    = shift;
    my $href    = shift;
    my $amq     = $self->activemq;
    my $log     = $self->log;
    my $mongo   = $self->mongo;

    #   short circuiting because this does nothing currently
    #  this is the way we would like to do it, but it confuses the
    # stomp clients for some reason.
    return;

    my $target_type = $href->{data}->{target_type} // "none";
    my $target_id   = $href->{data}->{target_id};
    my $is_task     = $href->{is_task};

    my $amq_msg = {
        type    => $target_type,
        id      => $target_id,
        action  => $href->{type},
    };

    if ( $is_task) {
        $amq_msg->{is_task} = $is_task;
    }

    my $viewcount   = $href->{data}->{view_count};
    if ( $viewcount ) {
        $amq_msg->{view_count} = $viewcount;
    }

    if ( $target_type eq "alert" ) {

        if ( $target_id ) {

            my $alert_obj = $mongo->read_one_document({
                collection  => "alerts",
                match_ref   => { alert_id => $target_id },
            });

            unless ($alert_obj) {
                $log->error("Audit for Alert $target_id failed to find");
            }
            else {
                $amq_msg->{alertgroup} = $alert_obj->alertgroup;
            }

        }
        else {
            $log->error("Audit had no target_id...");
        }
    }

    my $orig_hash = $href->{data}->{original_obj};

    if ( defined $orig_hash->{target_id} ) {
        $amq_msg->{target_type} = $orig_hash->{target_type};
        $amq_msg->{target_id}   = $orig_hash->{target_id};
    }
    # disabled, need to use once refactor sorts out message inconsistancies
    # so currently this whole function does nothing!
    # $activemq->send("activity", $amq_msg);
}

=item C<map_thing_to_collection>

give it a thing (alert, event, etc.) name and get the
mongo collection that stores it.

in future, consider making this a class method on the model.

=cut

sub map_thing_to_collection {
    my $self        = shift;
    my $thing       = shift;
    my $map_href    = {
        alert           => "alerts",
        event           => "events",
        incident        => "incidents",
        intel           => "intels",
        entry           => "entries",
        guide           => "guides",
        alertgroup      => "alertgroups",
        audit           => "audits",
        file            => "files",
        tag             => "tags",
        user            => "users",
        checklist       => "checklists",
        plugin          => "plugins",
        plugininstance  => "plugininstances",
    };
    my $collection  = $map_href->{$thing};

    unless ( defined $collection ) {
        $self->log->error("Thing $thing has no collection mapping!");
        return undef;
    }
    return $collection;
}


1;
