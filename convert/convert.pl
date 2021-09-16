#!/bin/env perl
use strict;
use warnings;
use DateTime;
use DateTime::Format::Pg;
use Tie::IxHash;

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
            view_count
            firstview_date
            message_id
            subject
            body
            backrefs
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
    my $mongo       = shift; # not meerkat
    my $dbh         = shift; # postgres
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

