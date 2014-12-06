package Scot::Model::IncidentHandler;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME
 Scot::Model::User - a moose obj rep of a Scot User

=head1 DESCRIPTION
 Definition of an A User
=cut

extends 'Scot::Model';

=head2 Attributes

=cut
with (  
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
);

=item C<username>
 string representation of users login
=cut
has user    => (
    is          =>  'rw',
    isa         =>  'Str',
    required    =>  1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

has date    => (
    is          => 'rw',
    isa         => 'DateTime',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

sub get_datetime {
    my $self    = shift;
    my $dstring = shift;

    my ($date, $junk, $month, $day, $year);

    ($date, $junk) = split(/ /, $dstring, 2);

    my $dt;

    if ( $date =~ /\d+/ ) {
        ($month, $day, $year) = split(/\//, $date, 3);

        $dt = DateTime->new(
            year    => $year,
            month   => $month,
            day     => $day,
            hour    => 0,
            minute  => 0,
            second  => 0,
        );
    }
    else {
        my $strp    = DateTime::Format::Strptime->new(
            pattern => '%a %b %d %Y %T %Z',
            locale  => 'en_US',
        );
        $dt     = $strp->parse_datetime($dstring);
    }

    return $dt;
}

__PACKAGE__->meta->make_immutable;
1;
