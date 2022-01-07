package Scot::Types;

use Moose;
use Moose::Util::TypeConstraints;

=head1 Scot::Types

custom moose types for use within scot

=cut

=item B<Epoch>

integer > 0 that will represent the seconds since the unix epoch

=cut

subtype 'Epoch',
as      'Int',
where   { $_ >= 0 };

coerce  'Epoch',
from    'Str', via  { $_ + 0 },
from    'Num', via  { int($_); };

=item B<IID>

integer > 0 used in iid attribute for model instances

=cut

subtype 'IID',
as      'Int',
where   { $_ >= 0 };

coerce  'IID',
from    'Str', via  { $_ + 0 },
from    'Num', via  { int($_); };

coerce  'Num',
from    'Str', 
via     { $_ + 0 };

=item B<AlertgroupStatus>

=cut

subtype 'AlertgroupStatus',
as      'Str',
where   { grep { /$_/ } qw(open promoted closed) };

coerce  'AlertgroupStatus',
from    'Str',
via     {
    my ($n,$d) = split(/\//, $_, 2);
    if ($n =~ /\d+/ and $n >=1 ) {
        return 'promoted';
    }
    return 'open';
};

subtype 'ScotDomain',
as      'Object',
where   { 
    my $name    = ref($_);
    return $name =~ /^Scot::Domain::/;
};
subtype 'ScotCollection',
as      'Object',
where   { 
    my $name    = ref($_);
    return $name =~ /^Scot::Collection/;
};

=item B<alert_status>

Valid statuses for Alerts/Alertgroups

=cut

enum 'alert_status', [qw(open closed promoted)];

=item B<event_status>

Valid Statuses for Events

=cut

enum 'event_status', [ qw(open closed monitored) ];

=item B<TLP_color>

unset   = the absense of a TLP marking
white   = Unlimited Release
green   = sector wide release
amber   = distro limited to local parties/trusted partners
red     = do not share without permission from author
black   = do not share and "you didn't hear this from me"

=cut

enum 'TLP_color', [qw(unset white green amber red black)];

1;


