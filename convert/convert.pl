#!/bin/env perl
use strict;
use warnings;
use DateTime;
use DateTime::Format::Pg;
use Tie::IxHash;
use MongoDB;
use DBI;

my $mongo   = MongoDB->connect('mongodb://localhost/scot-prod');
my $dbh     = DBI->connect("dbi:Pg:dbname=scot4", '', '', {AutoCommit => 1});

process_alertgroups();

sub get_table_data {
    my $table   = shift;

    my %tables  = (
        alertgroup  => [qw(
            alertgroup_id
            created_date
            modified_data
            owner
            tlp
            alert_count
            open_count
            closed_count
            promoted_count
            view_count
            firstview_date
            message_id
            subject
            body
            backrefs
        )],
        alerts  => [qw(
            alert_id
            alertgroup_id
            created_date
            modified_date
            owner
            tlp 
            status
            parsed
            entry_count
        )],
        alert_data => [qw(
            alert_id
            schema_key_id
            data_value
            data_value_flaired
        )],
        alertgroup_schema_keys => [qw(
            schema_key_id
            alertgroup_id
            schema_key_name
            schema_key_type
            schema_key_order
        )],
    );

    my @columns = @{$tables{$table}};
    my @pholders = map { '?' } @columns;
    my $cols    = join(', ', map { qq{"$_"} } @columns);
    my $phs     = join(', ', @pholders);
    my $sql     =  qq{ INSERT INTO $table ($cols)) VALUES ( $phs ) };

    return {
        sql     => $sql,
        columns => \@columns,
    };
}


sub process_alertgroups {
    my $startid     = shift // 0;
    my $collection  = $mongo->get_collection('alertgroup');
    my $query       = { id => {'$gte' => $startid}};
    my $count       = $collection->count($query);
    my $cursor      = $collection->find($query);
    my $tabledata   = get_table_data('alertgroup');
    my $insertsql   = $tabledata->{sql};
    my $columns     = $tabledata->{columns};
    my $sth         = $dbh->prepare($insertsql);

    while (my $alertgroup = $cursor->next) {
        process_alertgroup($sth, $columns, $alertgroup);
    }
}

sub process_alertgroup {
    my $sth         = shift;
    my $columns     = shift;
    my $alertgroup  = shift;

    my %new_ag_row  = build_alertgroup_row($alertgroup);
    my @data        = build_values($columns,\%new_ag_row);
    $sth->execute(@data);

    process_alerts($alertgroup);
}

sub process_alerts {
    my $self            = shift;
    my $alertgroup      = shift;
    my $collection      = $mongo->get_collection('alert');
    my $alertgroup_id   = $alertgroup->{id};
    my $query           = { alertgroup => $alertgroup_id };
    my $count           = $collection->count($query);
    my $cursor          = $collection->find($query);

    my $alert_data              = get_table_data('alert_data');
    my $alertgroup_schema_keys  = get_table_data('alertgroup_schema_keys');
    my $alerts                  = get_table_data('alerts');

    my $sth_alert_data              = $dbh->prepare($alert_data->{sql});
    my $alert_columns               = $alert_data->{columns};
    my $sth_alertgroup_schema_keys  = $dbh->prepare($alertgroup_schema_keys->{sql});
    my $sth_alerts                  = $dbh->prepare($alerts->{sql});

    while (my $alert = $cursor->next) {
        my %new_alert   = build_alert_row($alert);
        my @alert_data  = build_values($alert_columns, \%new_alert);
        $sth_alerts->execute(@alert_data);
    }
}

sub build_values {
    my $columns = shift;
    my $href    = shift;
    my @data    = ();

    foreach my $key (@$columns) {
        push @data, $href->{$key};
    }
    return wantarray ? @data : \@data;
}

sub build_alertgroup_row {
    my $alertgroup  = shift;
    my %sqlrow      = ();
    my $tie = tie (%sqlrow, 'Tie::IxHash', 
        id              => $alertgroup->{id},
        created_date    => convert_epoch($alertgroup->{created}),
        modified_date   => convert_epoch($alertgroup->{updated}),
        owner           => $alertgroup->{owner},
        tlp             => $alertgroup->{tlp},
        alert_count     => $alertgroup->{alert_count},
        open_count      => $alertgroup->{open_count},
        closed_count    => $alertgroup->{closed_count},
        promoted_count  => $alertgroup->{promoted_count},
        view_count      => $alertgroup->{views},
        firstview_date  => $alertgroup->{firstview},
        message_id      => $alertgroup->{message_id},
        subject         => $alertgroup->{subject},
        body            => $alertgroup->{body},
        backrefs        => $alertgroup->{ahrefs},
    );
    return wantarray ? %sqlrow : \%sqlrow;
}

sub convert_epoch {
    my $epoch   = shift;
    my $dt      = DateTime->from_epoch(epoch => $epoch);
    # dt is UTC by default when doing from_epoch
    my $tstz    = DateTime::Format::Pg->format_timestamptz($dt);
    return $tstz;
}

