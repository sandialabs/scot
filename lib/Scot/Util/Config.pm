package Scot::Util::Config;

use lib '../../../lib';
use strict;
use warnings;
use v5.18;
use File::Find;
use Safe;

use Moose 2;

has file => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has paths   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [ '/opt/scot/etc' ]; },
);
    
sub get_config {
    my $self    = shift;
    my $file    = shift // $self->file;
    my $paths   = shift // $self->paths;    # expect array ref

    my $fqname;
    find(sub {
        if ( $_ eq $file ) {
            $fqname = $File::Find::name;
            return;
        }
    }, @$paths);

    no strict 'refs'; # I know, but...
    my $cont    = new Safe 'MCONFIG';
    my $r       = $cont->rdo($fqname);
    my $hname   = 'MCONFIG::environment';
    my %copy    = %$hname;
    my $href    = \%copy;

    if (defined $href->{include} ) {
        my $inchref = delete $href->{include};
        
        foreach my $attr (keys %$inchref) {
            $href->{$attr} = $self->get_config($inchref->{$attr});
        }
    }
    return $href;
}

__PACKAGE__->meta->make_immutable;
1;        
__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

