package Scot::Collection::Intel;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Intel

=head1 Description

Custom collection operations for Intel

=head1 Methods

=over 4

=item B<create_from_handler($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Custom create in Scot::Collection::Intel");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    unless ( $json->{readgroups} ) {
        $json->{groups}->{read}   = $env->default_groups->{read};
    }
    unless ( $json->{modifygroups} ) {
        $json->{groups}->{modify} = $env->default_groups->{modify};
    }

    my $intel   = $self->create($json);

    my $id  = $intel->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $env->mongo->collection('Source');
        $col->add_source_to("intel", $intel->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $env->mongo->collection('Tag');
        $col->add_source_to("intel", $intel->id, \@tags);
    }

    return $intel;

}

override get_subthing => sub {
    my $self        = shift;
    my $thing       = shift;
    my $id          = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $id += 0;

    if ( $subthing eq "entry" ) {
        my $col = $mongo->collection('Entry');
        my $cur = $col->get_entries_by_target({
            id      => $id,
            type    => 'alert'
        });
        return $cur;
    }
    elsif ( $subthing eq "entity" ) {
        my $timer  = $env->get_timer("fetching links");
        my $col    = $mongo->collection('Link');
        my $ft  = $env->get_timer('find actual timer');
        my $cur    = $col->get_links_by_target({ 
            id => $id, type => 'alertgroup' 
        });
        &$ft;
        my @lnk = map { $_->id } $cur->all;
        &$timer;

        $timer  = $env->get_timer("generating entity cursor");
        $col    = $mongo->collection('Entity');
        $cur    = $col->find({id => {'$in' => \@lnk }});
        &$timer;
        return $cur;
    }
    elsif ( $subthing eq "tag" ) {
        my $col = $mongo->collection('Appearance');
        my $cur = $col->find({
            type            => 'tag',
            'target.type'   => 'intel',
            'target.id'     => $id,
        });
        my @ids = map { $_->{apid} } $cur->all;
        $col    = $mongo->collection('Tag');
        $cur    = $col->find({ id => {'$in' => \@ids }});
        return $cur;
    }
    elsif ( $subthing eq "source" ) {
        my $col = $mongo->collection('Appearance');
        my $cur = $col->find({
            type            => 'source',
            'target.type'   => 'intel',
            'target.id'     => $id,
        });
        my @ids = map { $_->{apid} } $cur->all;
        $col    = $mongo->collection('Source');
        $cur    = $col->find({ id => {'$in' => \@ids }});
        return $cur;
    }
    elsif ( $subthing eq "history" ) {
        my $col = $mongo->collection('History');
        my $cur = $col->find({'target.id'   => $id,
                              'target.type' => 'intel',});
        return $cur;
    }
    else {
        $log->error("unsupported subthing $subthing!");
    }
};

1;
