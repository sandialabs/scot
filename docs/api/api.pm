=pod

=head1 API

=cut

=head2 Description

Documentaton of the SCOT REST API

=head2 PATHS


=over 4

=item B<GET /scot/api/v2/$model>

retrieve a set of alertgroups.

=item I<applies to>

=over 4

=item Alertgroup

=item Alert
 
=item Intel

=item Event

=item Entry

=item Incident

=item File

=item Handler

=back

=item I<returns>

JSON object of Form:

=over 4

    {
        totalRecords:       int,
        returnedRecords:    int,
        records:    [
            { record_hash },
            ...
        ],
    }

=back

where record_hash is the JSON representation of the Alertgroup record.  See
L<Model> for details.

=item I<consumes>

can send HTML parameters on url or JSON to modify the return results

=over 4

=item match

hash (JSON obj) of column names and conditions to match.

=item sort

JSON object in mongo format specifying the sort columns/directions

=item columns

array of column names to display,  if empty, all columns will be returned.

=item limit

the limit to the number of records returned.

=item offset

start returning records after offset.

=back

=back



