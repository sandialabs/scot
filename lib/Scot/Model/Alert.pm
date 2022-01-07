package Scot::Model::Alert;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Alert

=head1 Description

The model of an individual alert

=cut

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Data
    Scot::Role::Entitiable
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Parsed
    Scot::Role::Promotable
    Scot::Role::Status
    Scot::Role::Subject
    Scot::Role::Times
    Scot::Role::TLP
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Data
    Scot::Role::Entitiable
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Parsed
    Scot::Role::Promotable
    Scot::Role::Status
    Scot::Role::Subject
    Scot::Role::Times
    Scot::Role::TLP

=head1 Sample JSON object representation

	{
		"_id" : ObjectId("9b900bb6d670123a9878b213"),
		"tlp" : "unset",
		"created" : 1536166838,
		"parsed" : 1,
		"updated" : 1536166838,
		"groups" : {
			"read" : [
				"wg-scot-ir",
				"wg-scot-researchers"
			],
			"modify" : [
				"wg-scot-ir"
			]
		},
		"promotion_id" : 0,
		"entry_count" : 0,
		"alertgroup" : 1576257,
		"owner" : "scot-admin",
		"location" : "snl",
		"when" : 1536166838,
		"data" : {
			"subject" : [
				"New Document(s) Notice"
			],
			"x-rcpt-from" : [
				"foo.a.bar@bcompany.com"
			],
			"alert_name" : "Link to file in email",
			"_time" : [
				"Wed Sep 5 10:02:08 2018"
			],
			"urls{}" : [
				"https://foo.bcompany.com/cgi-bin/apps/s/index.cgi?a=38&s=135"
			],
			"quarantined" : [
				"false"
			],
			"scanid" : [
				"0a88ca88-b185-18e8-8b5d-5865838d8087"
			],
			"mail-from" : [
				"Foo A Bar <foo.a.bar@bcompayn.com>"
			],
			"summary-flags{}" : [
				"yr:reply_language"
			],
			"message-id" : [
				"201809051554.w85Fsmjp844479@ewa-av-01.mbs.bcompany.net"
			],
			"mail-to" : [
				"James Brown <god.father.soul@soul.music>",
			],
			"columns" : [
				"_time",
				"quarantined",
				"subject",
				"mail-from",
				"x-rcpt-from",
				"mail-to",
				"x-rcpt-all",
				"urls{}",
				"message-id",
				"scanid",
				"summary-flags{}"
			],
			"search" : "search params"
		},
		"columns" : [
			"_time",
			"quarantined",
			"subject",
			"mail-from",
			"x-rcpt-from",
			"mail-to",
			"x-rcpt-all",
			"urls{}",
			"message-id",
			"scanid",
			"summary-flags{}"
		],
		"id" : 41118600,
		"data_with_flair" : {
			"alert_name" : "<br><div>Link to zip file in email </div>",
			"mail-from" : "<br><div>Foo A Bar <span class=\"entity message_id\" data-entity-type=\"message_id\" data-entity-value=\"&lt;foo.a.bar@bcompany.com&gt;\">&lt;foo.a.bar@bcompany.com&gt;</span></div>",
			"subject" : "<br><div>New Document(s) Notice</div>",
			"x-rcpt-from" : "<br><div><span class=\"entity email\" data-entity-type=\"email\" data-entity-value=\"foo.a.bar@bcompany.com\">foo.a.bar@<span class=\"entity domain\" data-entity-type=\"domain\" data-entity-value=\"bcompany.com\">bcompany.com</span></span></div>",
			"scanid" : "<br><span class=\"entity uuid1\"  data-entity-value=\"0a85ca30-b125-11e8-8b5d-5765b31d50b7\"  data-entity-type=\"uuid1\">0a85ca30-b125-11e8-8b5d-5765b31d50b7</span>",
			"search" : "search params",
			"urls{}" : "<br><div>https://<span class=\"entity domain\" data-entity-type=\"domain\" data-entity-value=\"programs.web.bcompany.com\">programs.web.bcompany.com</span>/cgi-bin/apps/s/index.cgi?a=386564&amp;s=135</div>",
			"quarantined" : "<br><div>false</div>",
			"x-rcpt-all" : "<br><div></div>",
			"summary-flags{}" : "<br><div>yr:reply_language</div>",
			"_time" : "<br><div>Wed Sep 5 10:02:08 2018</div>",
			"mail-to" : "<br><div>James Brown <span class=\"entity message_id\" data-entity-type=\"message_id\" data-entity-value=\"&lt;god.father.soul@soul.music&gt;\">&lt;god.father.soul@soul.music.&gt;</span>"
				"James Brown <god.father.soul@soul.music>",
		},
		"status" : "open"
	}

=head1 Attributes

=over 4

=item B<alertgroup>

the integer id of the alertgroup this alert belongs in

=cut

has alertgroup  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<status>

the status of the alert
from Scot::Role::Status
valid statuses defined by Alertstatus in Types.pm

=cut


=item B<parsed>

was this alert parsed (true = 1) otherwise we will need the original html
from Scot::Role::Parsed

=cut

=item B<data>

the hash reference to the data extraced from the alert
from Scot::Role::Data

=cut


=item B<data_with_fair>

same as data, but with detected entities wraped in spans 
(or as we say flaired)
This is tricky though, we really only want to calculate 
flair when needed because of the expense

=cut

has data_with_flair => (
    is          => 'ro',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    required    => 1,
    default     => sub { {} },
);

=item B<columns>

the columns parsed from the data
not sure this is needed in scot like it was in vast
but tests break without it

=cut

has columns     => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub {[]},
);

sub get_memo {
    my $self    = shift;
    return $self->subject;
}

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
