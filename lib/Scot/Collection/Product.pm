package Scot::Collection::Product;
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

Custom collection operations for Product

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

    $log->trace("Custom create in Scot::Collection::Product");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    $json->{owner} = $user;

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    $self->validate_permissions($json);

    my $product   = $self->create($json);

    my $id  = $product->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $self->meerkat->collection('Source');
        $col->add_source_to("product", $product->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $self->meerkat->collection('Tag');
        $col->add_source_to("product", $product->id, \@tags);
    }

    return $product;
};

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $mongo   = $self->meerkat;

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'product',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'product' },
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
                'target.type'   => 'product',
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
                'target.type'   => 'product',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "history" ) {
        my $col = $mongo->collection('History');
        my $cur = $col->find({'target.id'   => $id,
                              'target.type' => 'product',});
        return $cur;
    }
    if ( $subthing eq "file" ) {
        my $col = $mongo->collection('File');
        my $cur = $col->find({
            'entry_target.type' => 'product',
            'entry_target.id'   => $id,
        });
        return $cur;
    }
    die "Unsupported product subthing $subthing";
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
    my $object  = shift; # an Intel
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $request = $req->{request};

    my $promo_id = $request->{json}->{promote} //
                    $request->{params}->{promote};

    $log->debug("Getting promotion object $promo_id");

    my $product;

    if ( $promo_id =~ /\d+/ ) {
        $product = $self->find_iid($promo_id);
        if ( defined $product and 
             ref($product) eq "Scot::Model::Product" ) {
            return $product;
        }
        die "Product $promo_id does not exist.";
    }
    if ( $promo_id eq "new" or ! defined $promo_id ) {
        $product = $self->create_promotion($object, $req);
        return  $product;
    }
    die "Invalid promotion id";
}

sub create_promotion {
    my $self    = shift;
    my $object  = shift; # an Intel
    my $req     = shift;
    my $user    = $req->{user};
    my $subject = $object->subject //
                  $self->get_value_from_request($req, "subject");
    my $href    = {
        subject     => $subject,
        owner       => $user,
        status      => 'open',
        promoted_from   => [ $object->id ],
    };

    my $product = $self->create($href);
    return $product;
}
        

1;
