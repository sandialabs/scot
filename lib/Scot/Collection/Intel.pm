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


override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Custom create in Scot::Collection::Intel");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    $json->{owner} = $user;

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    $self->validate_permissions($json);

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
            type    => 'intel',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'intel' },
                        'entity' );
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

    if ( $subthing eq "tag" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'tag', 
                'target.type'   => 'intel',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Tag')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "source" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'source', 
                'target.type'   => 'intel',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "history" ) {
        my $col = $mongo->collection('History');
        my $cur = $col->find({'target.id'   => $id,
                              'target.type' => 'intel',});
        return $cur;
    }
    if ( $subthing eq "file" ) {
        my $col = $mongo->collection('File');
        my $cur = $col->find({
            'entry_target.type' => 'intel',
            'entry_target.id'   => $id,
        });
        return $cur;
    }
    die "Unsupported intel subthing $subthing";
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

sub get_promotion_obj {
    my $self    = shift;
    my $object  = shift; # a dispatch
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $request = $req->{request};

    # if given a promo_id, promote into an existing
    my $promo_id    =  $request->{json}->{promote} // 
                        $request->{params}->{promote};

    $log->debug("Getting promotion object $promo_id for ".ref($object));

    my $intel;

    if ( $promo_id =~ /\d+/ ) {
        $intel = $self->find_iid($promo_id);
        if ( defined $intel and ref($intel) eq "Scot::Model::Intel" ) {
            return $intel;
        }
        die "Intel $promo_id does not exist.  Can not promote to missing Intel.";
    }
    if ( $promo_id eq "new" or ! defined $promo_id ) {
        $intel = $self->create_promotion($object, $req);
        return $intel;
    }
    die "Invalid Promotion";
}

sub create_promotion {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $user    = $req->{user};
    my $subject = $self->get_subject($object) // $self->get_value_from_request($req, "subject");

    return $self->create({
        subject => $subject,
        status  => 'open',
        owner   => $user,
        promoted_from => [ $object->id ],
    });
}

sub get_subject {
    my $self    = shift;
    my $object  = shift;

    my $subject = $object->subject;
    if (!defined $subject){
        $subject = "Promoted Dispatch ".$object->id;
    }
    return $subject;
}

1;
