package Scot::App::Convert;

use strict;
use warnings;
use DateTime;
use DateTime::Format::Pg;
use Tie::IxHash;
use Mojo::JSON qw(encode_json);
use Time::HiRes qw(gettimeofday tv_interval);
use MongoDB;
use DBI;
use DBD::Pg qw(:pg_types);
use v5.26;

use Moose;

has log => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    required    => 1,
    builder     => '_build_logger',
);

sub _build_logger {
    my $self    = shift;
    my $log     = Log::Log4perl->get_logger('convert');
    my $layout  = Log::Log4perl::Layout::PatternLayout->new('%d %7p [%P] %15F{1}: %4L %m%n');
    my $append  = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::File',
        name    => 'convert_log',
        filenam => '/var/log/scot/convert.log',
        autoflush => 1,
    );
    $append->layout($layout);
    $log->add_appender($append);
    $log->level('DEBUG');
    return $log;
}

has mongo   => (
    is          => 'ro',
    isa         => 'MongoDB::Client',
    required    => 1,
    builder     => '_build_mongo',
);

sub _build_mongo {
    my $self    = shift;
    my $dbname  = 'scot-prod';
    my $host    = 'mongodb://localhost';
    my $writesafety = 1;
    my $findmaster  = 1;
    my $mongo       = MongoDB::MongoClient->new(
        host    => $host,
        db_name => $dbname,
        w       => $writesafety,
    );
    return $mongo;
}

has dbh     => (
    is          => 'ro',
    isa         => 'DBD::Pg',
    required    => 1,
    builder     => '_build_dbh',
);

sub _build_dbh {
    my $self    = shift;
    my $dbname  = "scot";
    my $conn    = "dbi:Pg:dbname=$dbname";
    my $user    = "scot";
    my $pass    = $ENV{'pgpass'};
    my $options = { AutoCommit => 0 };
    my $dbh     =DBI->connect($conn, $user, $pass, $options);
    return $dbh;
}

has alertgroup_mapping  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_alertgroup_mapping',
);

sub _build_alertgroup_mapping {
    my $self        = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
        alertgroup_id   => [ 'id', 'integerify' ],
        created_date    => [ 'created', 'convert_epoch' ],
        modified_date   => [ 'updated', 'convert_epoch' ],
        owner           => [ 'owner', 'stringify' ],
        tlp             => [ 'tlp', 'tlpify' ],
        alert_count     => [ 'alert_count', 'integerify' ],
        open_count      => [ 'open_count', 'integerify' ],
        closed_count    => [ 'closed_count', 'integerify' ],
        promoted_count  => [ 'promoted_count', 'integerify' ],
        view_count      => [ 'views', 'integerify'],
        firstview_date  => [ 'firstview', 'convert_epoch' ],
        message_id      => [ 'message_id', 'not_nullify' ],
        subject         => [ 'subject', 'not_nullify' ],
        body            => [ 'body', 'not_nullify' ],
        backrefs        => [ 'ahrefs',  'jsonify' ],
    );
    return \%map;
}

has alert_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_alert_mapping',
);

sub _build_alert_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
        alert_id        => [ 'id', 'integerify' ],
        created_date    => [ 'created', 'convert_epoch' ],
        modified_date   => [ 'updated', 'convert_epoch' ],
        owner           => [ 'owner', 'stringify' ],
        tlp             => [ 'tlp', 'tlpify' ],
        status          => [ 'status', 'alertstatusify' ],
        parsed          => [ 'parsed', 'booleanify' ],
        entry_count     => [ 'entry_count', 'integerify' ],
        alert_keys      => [ 'columns', 'arrayify' ],
        alert_data      => [ 'data', 'hashify' ],
        alert_data_flaired => [ 'data_with_flair', 'hashify' ],
        alertgroup_id   => [ 'alertgroup', 'integerify' ],
    );
    return \%map;
}

has event_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_alert_mapping',
);

sub _build_event_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

has incident_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_incident_mapping',
);

sub _build_incident_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

has dispatch_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_dispatch_mapping',
);

sub _build_dispatch_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

has intel_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_intel_mapping',
);

sub _build_intel_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

has product_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_product_mapping',
);

sub _build_product_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

has apikey_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_apikey_mapping',
);

sub _build_apikey_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

has appearance_mapping   => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_appearance_mapping',
);

sub _build_appearance_mapping {
    my $self    = shift;
    my %map         = ();
    my $tie         = tie (%map, 'Tie::IxHash',
    );
    return \%map;
}

sub numberify {
    my $self    = shift;
    my $value   = shift;
    return $value + 0;
}

sub integerify {
    my $self    = shift;
    my $value   = shift;
    return int( $value + 0 );
}

sub convert_epoch {
    my $self    = shift;
    my $value   = shift;
    my $dt      = DateTime->from_epoch( epoch => $value );
    my $tstz    = DateTime::Format::Pg->formattimestamptz($dt);
    return $tstz;
}

sub stringify {
    my $self    = shift;
    my $value   = shift;
    return $value;
}

sub tlpify {
    my $self    = shift;
    my $value   = shift;
    my @valid   =(qw(unset white amber red black));

    if ( grep {/^$value$/} @valid ) {
        return $value;
    }
    return 'unset';
}

sub not_nullify {
    my $self    = shift;
    my $value   = shift;

    if ( defined $value ) { 
        return $value;
    }
    return ' ';
}

sub jsonify {
    my $self    = shift;
    my $value   = shift;
    return encode_json $value;
}

sub build_columns {
    my $self    = shift;
    my $map     = shift;
    my @cols    = map { qq{"$_"} } keys %$map;
    return wantarray ? @cols : \@cols;
}

sub build_placeholders {
    my $self    = shift;
    my $map     = shift;
    my @holders = map { '?' } keys %$map;
    return wantarray ? @holders : \@holders;
}

sub build_insert {
    my $self    = shift;
    my $table   = shift;
    my $map     = shift;
    my $cols    = join(', ', $self->build_columns($map));
    my $phs     = join(', ', $self->build_placeholders($map));
    my $sql     = qq{INSERT INTO $table ($cols) VALUES ($phs)};
    return $sql;
}

sub process_alertgroups {
    my $self    = shift;
    my $startid = shift // 0;
    my $mongo   = $self->mongo;
    my $dbh     = $self->dbh;
    my $log     = $self->log;

    my $agcol   = $mongo->get_collection('alertgroup');
    my $query   = { id => { '$gte' => $startid } };
    my $count   = $agcol->count($query);
    my $cursor  = $agcol->find($query);
    $cursor->immortal(1);

    my $mapping     = $self->alertgroup_mapping;
    my $insertsql   = $self->build_insert('alertgroup', $mapping);
    my $sth         = $dbh->prepare($insertsql);

    my $countdown   = $self->get_countdown('Alertgroups', $count);

    while ( my $alertgroup = $cursor->next ) {
        $self->process_alertgroup($sth, $alertgroup);
        my $msg = &$countdown;
        $log->debug($msg);
    }
}

sub build_object_permissions {
    my $self        = shift;
    my $target_type = shift;
    my $target_id   = shift;
    my $origperms   = shift;
    my $dbh         = $self->dbh;
    my $log         = $self->log;

    state $sth = $dbh->prepare(
        qq{INSERT INTO object_permissions (role_id, target_type, target_id, permission VALUES (?, ?, ?, ?) }
    );

    foreach my $permission (keys %$origperms) {
        my @roles   = map { $self->lookup_role($_) } @{$origperms->{$permission}};
        foreach my $role (@roles) {
            $sth->execute($role, $target_type, $target_id, $permission);
            my $lastid = $sth->last_insert_id();
            $log->debug("Inserted object_permission row $lastid : $role : $target_type : $target_id : $permission");
        }
    }
}

sub process_alertgroup {
    my $self    = shift;
    my $sth     = shift;
    my $ag      = shift;
    my $log     = $self->log;
    my $agcol   = $self->mongo->get_collection('alertgroup');
    my @values  = $self->get_values($ag);
    $sth->execute(@values);
    my $lastid = $sth->last_insert_id();
    $log->debug("Inserted Alertgroup $lastid");
    $self->build_object_permissions( 'alertgroup', $ag->{id}, $ag->{groups});
}

sub get_values {
    my $self    = shift;
    my $href    = shift;
    my $map     = $self->alertgroup_mapping;
    my @values  = ();
    my $log     = $self->log;

    foreach my $column (keys %$map) {
        my ($skey, $mod) = $map->{$column};
        my $modval      = $self->$mod($href->{$skey});
        push @values, $modval;
    }
    $log->debug("values => ".join(', ',@values));
    return wantarray ? @values : \@values;
}

sub get_countdown {
    my $self    = shift;
    my $title   = shift;
    my $total   = shift;
    my $remain  = $total;
    my $done    = 0;
    my $st_time = [ gettimeofday ];
    my $timer   = sub {
        my $begin   = $st_time;
        my $elapsed = tv_interval($begin, [ gettimeofday ]);
        return $elapsed;
    };

    return sub {
        $remain --;
        $done ++;
        my $e   = &$timer;

        my $pct     = ( $done / $total ) * 100;
        my $rate    = ( $done / $e );
        my $ect     = ( $remain / $rate ) ;
        my $finish  = ( $ect / 60 );

        return join(' ',
            sprintf( "%d complete (%.2f%%).", $done, $pct),
            "$remain of $total.",
            sprintf( "rate: %.3f/sec", $rate),
            sprintf( "ECT: %.2f minutes", $finish)
        );
    };
}


1;
