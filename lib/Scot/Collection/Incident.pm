package Scot::Collection::Incident;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::File

=head1 Description

Custom collection operations for Files

=head1 Methods

=over 4

=item B<create_from_api($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->trace("Custom create in Scot::Collection::Incident");

    my $user    = $request->{user};
    my $json    = $request->{request}->{json};

    my @tags    = $env->get_req_array($json, "tags");

    my $incident    = $self->create($json);

    unless ($incident) {
        $log->error("ERROR creating Incident from ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    my $id  = $incident->id;

    if ( scalar(@tags) > 0 ) {
        $self->upssert_links("Tag", "incident", $id, @tags);
    }
    return $incident;
}

sub create_promotion {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;

    my $reportable      = $self->get_value_from_request($req, "reportable");
    my $subject         = $object->subject // 
                            $self->get_value_from_request($req, "subject");
    my $href    = {
        reportable  => $reportable ? 1 : 0,
        subject     => $subject,
    };
    my $category        = $self->get_value_from_request($req, "category");
    $href->{category}   = $category if (defined($category));
    my $sensitivity     = $self->get_value_from_request($req, "sensitivity");
    $href->{sensitivity} = $sensitivity if (defined $sensitivity);
    my $occurred        = $self->get_value_from_request($req, "occurred");
    $href->{occurred}   = $occurred if (defined $occurred);
    my $discovered      = $self->get_value_from_request($req, "discovered");
    $href->{discovered} = $occurred if (defined $discovered);

    my $incident = $self->create($href);
    return $incident;
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
    elsif ( $subthing eq "event" ) {
        my $inc = $self->find_iid($id);
        my $col = $mongo->collection('Event');
        my $cur = $col->find({ id => { '$in' => $inc->promoted_from } });
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
            'target.type'   => 'incident',
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
            'target.type'   => 'incident',
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
                              'target.type' => 'incident',});
        return $cur;
    }
    else {
        $log->error("unsupported subthing $subthing!");
    }
};

1;
