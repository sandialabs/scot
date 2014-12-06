package Scot::Roles::Dumpable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

requires 'log';

=head1 NAME

Scot::Roles::Dumpable

=head1 Description

Allows an object to be "dumped" to the log.  Helpful for debugging.

=head1 Methods

=over 4

=item C<dump>

dump the value of each attribute to the active log

=cut

sub dump {
    my $self    = shift;
    my $log     = $self->log;
    my $meta    = $self->meta;
    my @attrs   = $meta->get_all_attributes;

    local $Data::Dumper::Indent = 0;
    $log->debug("Dumping --- ".ref($self)." -----------");
    foreach my $name ( sort map { $_->name } @attrs ) {
        next if $name eq "log";
        my $line = sprintf("%15s => %s", $name, Dumper($self->$name));
        $log->debug($line);
    }
    $log->debug("-----------------------------------------");
}



1;

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
