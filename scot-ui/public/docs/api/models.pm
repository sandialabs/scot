=pod

=head1 Models

=cut

=head2 Description

Documentaton of the SCOT Database Models

=head2 Objects


=over 4

=item B<alert>

An alert is a row of data from a detection system.  

=over 4

=item I<alertgroup>

the integer id (foreign key) of the Alertgroup for this alert

=item I<data>

from Scot::Role::Data. Holds a JSON object of data from the detection system.

=item I<entry_count>

from Scot::Role::Entriable. Integer number of entries associated with this alert.

=item I<owner>

from Scot::Role::Permission. The username string of the owner.  Default owner is set in scot_env.cfg.

=item I<group>

from Scot::Role::Permission. A hash (or json object when in mongo) that contains two attributes:

=over 4

=item read

an array of group names that can read this alert

=item modify

an array of group names that can modify this alert

=back

=item I<parsed>

from Scot::Role::Parsed.  Contains 1 when this Alert has been parsed for flair.

=item I<promotion_id>

from Scot::Role::Promotable.  Contains the int id of the Event this Alert was promoted to.  Contains 0 if not promoted.

=item I<status>

from Scot::Role::Status.  String representation of the Status of the Alert.  Typically: "open", "closed", or "promoted".

=item I<data_with_flair>

The same as L<data> but with detected Entities flaired (wrapped in special spans)

=item I<columns>

Array of Column heading for the Alert row.

=back

=item B<alertgroup>

a collection of alerts.  Often detection systems send alerts in batches 
and it can be useful to associate the alerts that came in as group into
this collection.

=over 4

=item I<id>

the integer id, an alternate primary key to mongo's oid.

=item I<subject>

Subject line for detection engine

=back

=back


