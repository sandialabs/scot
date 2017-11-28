package Scot::Parser;

use lib '../../lib';
use Try::Tiny;
use Data::Dumper;
use Moose;

=item B<message_href>

The Hash Ref from the Scot::Util::Imap parsing of the email message.
Structure:

{
    imap_uid    => 
    body        =>
    envelope    => 
    subject     => 
    from        => 
    to          => 
    when        => epoch,
    message_id  => 
}

=cut


has log             => (
    is              => 'ro',
    isa             => 'Log::Log4perl::Logger',
    required        => 1,
);

1;
