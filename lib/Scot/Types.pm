package Scot::Types;

use Moose;
use Moose::Util::TypeConstraints;

=head1 Scot::Types

Moose custom types for use within Scot

=cut

subtype 'Epoch',
as      'Int',
where   { $_ >= 0 };

coerce  'Epoch',
from    'Str', via     { $_ + 0 },
from    'Num', via     { int($_); };

subtype 'iid',
as      'Int',
where   { $_ >= 0 };

coerce  'iid',
from    'Str', via     { $_ + 0 },
from    'Num', via  { int($_) };

coerce 'Num',
    from 'Str', via { $_ + 0 };


1;
