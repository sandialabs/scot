package Scot::Roles::Taggable;

use Moose::Role;
use Data::Dumper;
use lib '../../';
use Scot::Model::Tag;
use namespace::autoclean;

requires 'log';

has tags   => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    builder     => '_build_empty_tag_aref',
    handles     => {
        add_tag     => 'push',
        find_tag    => 'first_index',
        grep_tag    => 'grep',
        delete_tag  => 'delete',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

sub _build_empty_tag_aref {
    return [];
}

sub get_tags {
    my $self    = shift;
    my $mongo   = shift;
    my $type    = $self->get_my_type;
    my $idfield = $self->get_my_idfield;
    my $id      = $self->$idfield;

    my $matchref    = {
        'taggee.type'   => $type,
        'taggee.id'     => $id,
    };
    my @tagsrecs  = $mongo->read_documents({
        collection  => "tags",
        match_ref   => $matchref,
        sort_ref    => { text => 1 },
        all         => 1,
    });
    my @tags    = sort map { $_->text } @tagsrecs;
    $self->tags(\@tags);
    return \@tags;
}

sub add_to_tags {
    my $self    = shift;
    my $mongo   = shift;
    my $tag     = shift;
    my $log     = $self->log;

    if (!defined $mongo or ref($mongo) ne "Scot::Util::Mongo") {
        $log->error("Second param to add_tag needs to be a Scot::Util::Mongo");
        return undef;
    }

    if (!defined $tag or $tag eq '') {
        $log->error("3rd param is the tag and must be defined and not blank");
        return undef;
    }

    my @alreadytagged = $self->grep_tag( sub { /$tag/i } );

    unless (scalar(@alreadytagged) > 0 ) {
        $self->add_tag($tag);
        my $tag_aref    = $self->tags;
        @$tag_aref   = sort @$tag_aref;
        $self->tags($tag_aref);
        $mongo->update_document($self);
    }


    my $type    = $self->get_my_type;
    my $idfield = $self->get_my_idfield;
    my $id      = $self->$idfield;

    $log->debug("adding Tag $tag to $type $id");

    my $tagobj  = $mongo->read_one_document({
        collection  => "tags",
        match_ref   => {
            text    => $tag,
        },
    });

    if (defined $tagobj) {
        $tagobj->add_to_taggees({
            type    => $type,
            id      => $id,
        });
        $mongo->update_document($tagobj);
    }
    else {
        $tagobj = Scot::Model::Tag->new({
            text    => $tag,
            taggee   => [ {
                type    => $type,
                id      => $id,
            } ],
        });
        $mongo->create_document($tagobj);
    }
}

sub remove_tag {
    my $self    = shift;
    my $mongo   = shift;
    my $tag     = shift;
    my $log     = $self->log;

    if (!defined $mongo or ref($mongo) ne "Scot::Util::Mongo") {
        $log->error("2nd param to remove_tag needs to be a Scot::Util::Mongo");
        return undef;
    }

    if (!defined $tag or $tag eq '') {
        $log->error("3rd param is the tag and must be defined and not blank");
        return undef;
    }

    my $type    = $self->get_my_type;
    my $idfield = $self->get_my_idfield;
    my $id      = $self->$idfield;

    $log->debug("Removing tag $tag from $type $id");

    my $index   = $self->find_tag( sub { /$tag/i } );
    if ( $index > -1 ) {
        $self->delete_tag($index);
    }
    else {
        $log->error("Tag index of -1 returned.  Already gone?");
    }

    my $tagobj  = $mongo->read_one_document({
        collection  => "tags",
        match_ref   => {
            text    => $tag,
        },
    });

    if (defined $tagobj) {
        $tagobj->remove_taggee($type,$id);
        $mongo->update_document($tagobj);
    }
    else {
        $log->error("the tag you are trying to remove is already gone");
    }
}


sub get_my_type {
    my $self    = shift;
    my $ref     = ref($self);
    (my $type   = $ref) =~ s/Scot::Model::(.*)/$1/;
    return lc($type);
}

sub get_my_idfield {
    my $self    = shift;
    my $ref     = ref($self);
    (my $name   = $ref) =~ s/Scot::Model::(.*)/$1/;
    return lc($name) . "_id";
}
1;
