package Scot::Model::Alertgroup;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Alertgroup

=head1 Description

The model of an individual alertgroup.
Alertgroups are aggregations of alerts.  Why?
Splunk and other detectors often send in reports with multiple rows
of data.  Each row is broken into an alert.  This helps with various 
things from an automation point of view, but can be a pain for the analyst.
So this is a compromise to allow individual alerts to be aggregated into 
an anlyst friendly chunks.

=cut

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Body
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Parsed
    Scot::Role::Subject
    Scot::Role::Sources
    Scot::Role::Tags
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Views
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Body
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Parsed
    Scot::Role::Subject
    Scot::Role::Sources
    Scot::Role::Tags
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Views

=head1 Sample JSON object representation

    {
        "_id" : ObjectId("5b8f08b1d67012c18a5b0ea1"),
        "columns" : [
            "datetime",
            "quarantined",
        ],
        entry_count: 0,
        closed_count: 0, 
        tlp: "unset",
        id: 123,
        message_id: "asdfasdfk@sdfds.com",
        body: "text",
        body_plain: "text",
        body_flair: "text",
        view_history: {
            user: {
                when: 12412312312,
                where: "10.10.10.1",
            }
        },
        ahrefs: [
            {
                subject: "foobar",
                link: "https://foo.bar.com/search?s=123",
            },
        ],
        promotion_id: 0,
        status: "closed",
        promoted_count: 0,
        parsed: 1,
        entry_count: 1,
        alert_count: 2,
        firstview: 1536161212,
        owner: "scot-admin",
        type: "alertgroup"
    }

=head1 Attributes

=over 4

=item B<message_id>

the smtp message id of the email that generated the alertgroup, if it exists
This helps us in the reprocessing of mail inboxes

=cut

has message_id  => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => ' ',
);

has body_plain  => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => ' ',
);

=item B<status>

the status of the alertgroup: 'open', 'closed', 'promoted'

=cut

has status  => (
    is          => 'ro',
    isa         => 'alert_status',
    required    => 1,
    default     => 'open',
);

=item B<open_count>

Number of open alerts in this alertgroup

=cut

has open_count  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<closed_count>

Number of closed alerts in this alertgroup

=cut

has closed_count  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<promoted_count>

Number of promoted alerts in this alertgroup

=cut

has promoted_count  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<alert_count>

Number of  alerts in this alertgroup

=cut

has alert_count  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<columns>

used by ui to display alerts

=cut

has columns => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub {[]},
);

=item B<firstview>

this field is to track the first time someone viewed this alertgroup
view_history, tracks the last time someone viewed, so not as useful
for calculating response time metrics.  

API will detect that value is -1 and then update the firstview to the
seconds epoch when it was first viewed.

=cut

has firstview => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => -1, # means not viewed
);

=item B<ahrefs>

Some email messages contain HREFs back to the detection system
that may be helpful to analysts evaluating the alert.
This array will contain the <a href="xxx">xxx</a> for each one detected.

=cut

has ahrefs  => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
    traits      => [qw(Array)],
);

sub get_memo {
    my $self    = shift;
    return $self->subject;
}

=back

=head1 Methods

=cut

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
