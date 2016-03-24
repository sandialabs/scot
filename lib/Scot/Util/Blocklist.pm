package Scot::Util::Blocklist;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;

use Data::Dumper;
use DBI;
use DBD::mysql;
use DateTime;
use Date::Parse;

use Moose;
use namespace::autoclean;

## at some point this will be convert to a REST
## api like SCOT::UTIL::SCOT when Eric has it 
## ready.  until then, it is direct access to a 
## mysql db.

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
    default => sub { Scot::Env->instance },
);

=item B<servername>

this is the Blocklist DB server

=cut

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has database    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<username>

the username to access scot

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has password => ( 
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


=item B<blocklistpid>

for detection of forks

=cut

has blocklistpid => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => sub { $$+0 },
);

has dbh    => (
    is          => 'ro',
    isa         => 'DBI::db',
    required    => 1,
    lazy        => 1,
    builder     => '_build_dbi_connection',
    clearer     => 'clear_dbh',
);

sub _build_dbi_connection {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $dsn = "DBI:mysql:database=". $self->database .
              ";host=".$self->servername;
    my $dbh = DBI->connect($dsn, $self->username, $self->password);

    if ( $dbh ) {
        $log->debug("Connected to $dsn");
        return $dbh;
    }

    $log->error("ERROR: failed to connect to $dsn");
    return undef;
}

sub check_fork {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    if ( $$ != $self->blocklistpid ) {
        $log->trace("Fork detected, reconnecting to Blocklist DB");
        $self->blocklistpid($$);
        $self->clear_dbh;
    }
    return;
}

sub get_domain_block_status {
    my $self    = shift;
    my $domain  = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Getting Blocklist status for $domain");

    my $sql = qq|SELECT * FROM blockist_entries WHERE entry = ?|;

    my $sth = $self->do_sql($sql, $domain);

    my $result  = $sth->fetchrow_hashref;

    return $result;

}

sub get_bulk_domain_block_status {
    my $self    = shift;
    my @domains = @_;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Getting Blocklist status for ", join(',',@domains));

    my $sql = qq|SELECT * FROM blockist_entries WHERE entry IN |;
    my $dcount  = scalar(@domains);
    my @qmarks  = ();

    foreach (@domains) { push @qmarks, '?'; }

    $sql    = $sql . "(" . join(',',@qmarks) . ")";

    my $sth = $self->do_sql($sql, \@domains);

    my @results;

    while ( my $row = $sth->fetchrow_hashref ) {
        my $code    = $self->decifer_blockcode($row->{action});
        $row->{block_type}  = $code;
        push @results, $row;
    }
    return wantarray ? @results : \@results;
}

sub get_blocks_since {
    my $self    = shift;
    my $lastrun = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Getting Blocklist changes since $lastrun");
    my $sql =   qq|SELECT * FROM blocklist_entries WHERE eid IN |.
                qq|(SELECT eid FROM blocklist_history WHERE time > ?|;

    my $sth = $self->do_sql($sql, $lastrun);
    my @results;
    while ( my $row = $sth->fetchrow_hashref ) {
        my $code    = $self->decifer_blockcode($row->{action});
        $row->{block_type}  = $code;
        push @results, $row;
    }
    return wantarray ? @results : \@results;
}


sub decifer_blockcode {
    my $self    = shift;
    my $number  = shift;
    my %code    = (
        0       => 'allowed',
        1       => 'blocked',
        2       => 'whitelist',
        3       => 'warn',
        4       => 'blackholed',
        5       => 'firewalled',
    );
    return $code{$number};
}

sub do_sql {
    my $self    = shift;
    my $sql     = shift;
    my $aref    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Executing $sql with ", { filter =>\&Dumper, value => $aref});

    $self->check_fork;

    my $sth = $self->dbh->prepare($sql);
    if ( $sth->execute(@$aref) ) {
        return $sth;
    }
    $log->error("Error executing SQL: ". $sth->errstr);
    return undef;
}

1;
