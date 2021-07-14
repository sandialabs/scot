package Scot::Collection::Checklist;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

override api_create => sub {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $self->meerkat;
    my $log     = $env->log;
    my $json    = $href->{request}->{json};

    my @entries = @{delete $json->{entry}};
    $self->validate_permissions($json);
    my $checklist   = $self->create($json);

    my $entry_col   = $mongo->collection('Entry');
    if ( scalar(@entries) > 0 ) {
        foreach my $entry (@entries) {
            $entry->{owner} = $entry->{owner} // $href->{user};
            $entry->{task}  = {
                when    => $env->now,
                who     => $href->{user},
                status  => 'open',
            };
            $entry->{is_task} = 1;
            $entry->{target}    = {
                type    => "checklist",
                id      => $checklist->id,
            };
            my $obj = $entry_col->create($entry);
        }
    }
    return $checklist;
};

sub api_subthing {
    my $self        = shift;
    my $req         = shift;
    my $thing       = $req->{collection};
    my $id          = $req->{id} + 0;
    my $subthing    = $req->{subthing};
    my $mongo       = $self->meerkat;
    my $log         = $self->env->log;

    $log->debug("api_subthing /$thing/$id/$subthing");

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'checklist'
        });
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

    die "Unsupported subthing $subthing";
}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        subject => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{subject}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}
1;
