package Scot::Collection::Feed;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Feed

=head1 Description

Custom collection operations for Feed

=head1 Methods

=over 4

=item B<api_create>

Create an event and from a POST to the handler

=cut


override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Custom create in Scot::Collection::Feed");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    $json->{owner} = 'scot-rss';

    my @tags    = $env->get_req_array($json, "tags");

    $self->validate_permissions($json);

    $log->debug("Creating Feed with ",{filter=>\&Dumper,value=>$json});

    my $feed   = $self->create($json);

    my $id  = $feed->id;

    if ( scalar(@tags) > 0 ) {
        my $col = $env->mongo->collection('Tag');
        $col->add_source_to("feed", $feed->id, \@tags);
    }

    return $feed;
};

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $mongo   = $self->env->mongo;

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'feed',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                    ->get_linked_objects_cursor(
                        { id => $id, type => 'feed' },
                        'entity');
    }

    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id  => $id, type => $thing
                    });
    }

    if ( $subthing eq "tag" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'tag', 
                'target.type'   => 'feed',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Tag')->find({
            id => {'$in' => \@appearances}
        });
    }
    if ( $subthing eq "source" ) {
        my @appearances = map { $_->{apid} }
            $mongo->collection('Appearance')->find({
                type            => 'source',
                'target.type'   => 'event',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id  => { '$in' => \@appearances }
        });
    }

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')->find({
            'target.id'   => $id,
            'target.type' => 'event'
        });
    }

    die "Unsupported feed subthing $subthing";
}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        name => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{subject}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}

1;
