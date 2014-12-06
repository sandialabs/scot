package Scot::Roles::FileAttachable;

use Moose::Role;
# use Data::Dumper;
use namespace::autoclean;

# requires 'log';

=head1 Role

Scot::Roles::FileAttachable

=head1 Description

Give an object the ability to track related file uploads

=head1 Attributes

=over 4

=item C<files>

Array reference to file_id's of related File records

=cut

has files => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_empty_file_array',
    handles     => {
        all_files   => 'elements',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1,
    },
);

=back

=head1 Methods

=over 4

=cut

sub _empty_file_array {
    return [];
}

=item C<update_files_from_db>

read the database to get the current list of files
associated with this thing.

=cut

sub update_files_from_db {
    my $self    = shift;
    my $mongo   = shift;

    my $idfield = $self->idfield;
    my $myid    = $self->$idfield;
    my $type    = ref($self);
    (my $mytype  = $type) =~ s/Scot::Model::(.*)/$1/;
    $mytype     = lcfirst($mytype);

    my $cursor  = $mongo->read_documents({
        collection  => "files",
        match_ref   => {
            target_id   => $myid,
            target_type => $mytype,
        },
    });
    my @files = ();
    while (my $file_href = $cursor->next_raw) {
        push @files, {
            file_id     => $file_href->{file_id},
            filename    => $file_href->{filename},
        };
    }
    $self->files(\@files);
}

1;
__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=item L<Scot::Model>

=back
