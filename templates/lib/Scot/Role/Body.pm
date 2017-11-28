package Scot::Role::Body;

use Moose::Role;

=item B<body>

The "body" of the consuming role.  May be HTML.

=cut

has body => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => '',
);

=item B<body_plain>

The plaintext version of the body.

=cut

has body_plain => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => '',
);

=item B<body_flair>

The "flaired" version of body
in other words, defenitely html

=cut

has body_flair => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => '',
);

1;
