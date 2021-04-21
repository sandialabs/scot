package Scot::Collection::Sigbody;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

=head1 Name

Scot::Collection::Sigbody

=head1 Description

Custom collection operations on sigbody

=head1 Methods

=over 4

=item B<api_create>

Create Signature from POST to API

=cut

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->debug("Creating Sigbody from POST to API");
    $log->debug( Dumper($request) );

    my $json = $request->{request}->{json};

    $log->debug( "json is " . Dumper($json) );

    my $signatureid = $json->{signature_id};
    my $sigcol      = $mongo->collection('Signature');
    my $signature   = $sigcol->find_iid($signatureid);

    unless ( defined $signature ) {
        $log->error("Tried to create a Sigbody attached to non-existing Sig");
        return undef;
    }

    my $new_revision = $self->get_next_revision($signature);

    $json->{revision} = $new_revision;

    my $sigbody = $self->create($json);

    unless ($sigbody) {
        $log->error( "Error creating Sigbody from ",
            { filter => \&Dumper, value => $request } );
        return undef;
    }

    return $sigbody;
};

sub get_next_revision {
    my $self      = shift;
    my $signature = shift;

    my @command;
    # my $tie = tie( %command, "Tie::IxHash" );
    @command = (
        findAndModify => "signature",
        query         => { id => $signature->id },
        update        => { '$inc' => { latest_revision => 1 } },
        'new'         => 1,
        upsert        => 1,
    );
    my $mongo = $self->meerkat;
    my $revid = $self->_try_mongo_op(
        get_next_rev => sub {
            my $db_name = $mongo->database_name;
            my $db      = $mongo->_mongo_database($db_name);
            my $job     = $db->run_command( \@command );
            return $job->{value}->{latest_revision};
        }
    );
    return $revid;
}

1;
