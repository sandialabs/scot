package Scot::Roles::Closeable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

=head1 ROLE

Scot::Roles::Closeable

=head1 DESCRIPTION

This role confers the ability to track a closing time of the 
consuming object and to store a closing disposition.

=head1 Attributes

=over 4

=item C<closed>

 the positive integer inumber of seconds since the unix epoch
 closed is set when the record is closed by an analyst

=cut

has closed  => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<disposition>

 if something is closed, it might need a closing summary

=cut 

has disposition => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=back

=head1 Methods

=over 4

=item C<close>

set the closing time to the current time in seconds since unix epoch

=cut

sub close {
    my $self    = shift;
    $self->closed(time());
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

=item L<Scot::Model>

=back

