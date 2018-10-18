package Scot::Role::Body;
use Moose::Role;

=head1 Name

Scot::Role::Body

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<body>

Attribute that contains string data that may be plain text or HTML.  
This attribute may also contain a null value.

=cut

has body => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => '',
);

=item B<body_plain>

Attribute that contains a plain text rendering of the B<body> 
attribute.  
This attribute may also contain a null value.

=cut

has body_plain => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => '',
);

=item B<body_flair>

Attribute that contains the HTML version of the body after the text
has been scanned for entities and "flaired".  If Body is null, this
will be null also.

=back

=cut

has body_flair => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => '',
);


1;
