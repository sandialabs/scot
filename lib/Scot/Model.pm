package Scot::Model;

use Time::HiRes qw(gettimeofday);;
use utf8;
use Encode;
use Scot::Types;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 Scot::Model

This is the base object for all SCOT models.  Inherit from this
when you create new models.

=head2 Subtypes

=over 4

=item C<Epoch>

NOW IN SCOT::Types

this type is used to coerse timestamp fields and make sure we are 
talking about positive integers

=back



subtype 'Epoch',
    as  'Int',
    where   { $_ >= 0};

coerce 'Epoch',
    from 'Num',
    via     {
        int($_);
    };

=cut

=head2 Attributes

=over 4

=item C<log>

 the local reference to the logger

=cut

has 'log'   => (
    is          => 'rw',
    isa         => 'Maybe[Object]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => { serializable    => 0, },
);

=item C<_id>

 the MongoOID for the thing

=cut

has '_id'   => (
    is          => 'rw',
    isa         => 'MongoDB::OID',
    writer      => 'set_mongo_oid',
    predicate   => 'mongo_oid_set',
    clearer     => 'reset_oid',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<created>

 the positive integer number of seconds since unix epoch
 created tracks when it was put in the db, not user changeable

=cut

has 'created'   => (
    is          => 'ro',
    isa         => 'Epoch',
    coerce      => 1,
    required    => 1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);

=item C<updated>

 the positive integer number of seconds since unix epoch
 updated is set when the record is updated and written to the db

=cut

has 'updated'   => (
    is          => 'rw',
    isa         => 'Epoch',
    coerce      => 1,
    required    => 1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);


=item C<timezone>

 timezone to convert seconds epoch to
 not serializable, because this will be passed in 
 by the Handler.pm so user will see their choice

=cut

has 'timezone'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    builder     => "_get_default_timezone",
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
        gridviewable    => 1,
    },
);

=item C<controller>

 reference to the Mojolicious Controller that is operating on model

=cut    

has 'controller'    => ( 
    is          => 'rw',
    isa         => 'Maybe[Object]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
        gridviewable    => 0,
    },
);

=item C<env>

 the scot environment object

=cut

has 'env'   => (
    is      => 'rw',
    isa     => 'Maybe[Scot::Env]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
        gridviewable    => 0,
    },
);


sub _get_default_timezone {
    return 'UTC';
}

sub _build_empty_array {
    return [];
}

=item C<_timestamp>

 function to set the $now variable

=cut

sub _timestamp {
    my $self    = shift;
    my ($seconds, $microseconds) = gettimeofday();
    return $seconds;
}

=item C<fmt_time>

 function to format secs epoch into something understangable by humans

=cut

sub fmt_time {
    my $self    = shift;
    my $secs    = shift;
    my $tz      = $self->timezone;
    return '' unless $secs;
    my $dt  = DateTime->from_epoch( epoch => $secs );
       $dt->set_time_zone($tz);
    return sprintf("%s", $dt);
}

=item C<numberfy>

 perl assumes many variables are strings.  Normally, no big deal.
 however, the mongodb driver will not match perl string containing numbers
 to a numeric field.  "numberfy"-ing input will allow the match

=cut

sub numberfy {
    my $self    = shift;
    my $input   = shift;
    
    return $input + 0 if ( defined $input );
    return undef;
}

=item C<stringify>

 make sure input is treated as string

=cut

sub stringify {
    my $self    = shift;
    my $input   = shift;
    return $input . "" if (defined $input);
    return undef;
}

=item C<apply_changes>

 each model should define how to do this
 
=cut

sub apply_changes {
    my $self    = shift;
    my $log     = $self->log;

    $log->debug("Need to implement apply_changes in subclass!");

}

=item C<contraint_check>

 sometimes it is useful to check if data will blow up the model
 without actually blowing up

=cut

sub constraint_check {
    my $self    = shift;
    my $key     = shift;
    my $value   = shift;
    my $attribute   = $self->meta->find_attribute_by_name($key);
    my $constraint  = $attribute->type_constraint;
    return $constraint->check($value);
}

=item C<get_my_type>

This will return the type.  E.g. A Scot::Model::Alert will return "alert"

=cut

sub get_my_type {
    my $self    = shift;
    my $ref     = ref($self);
    (my $type = $ref) =~ s/Scot::Model:://;
    $type       = lcfirst($type);
    return $type;
}

=item C<encode_utf_8>

Fun and profit with utf8

=cut

sub encode_utf_8 {
    my $self    = shift;
    my $string  = shift;
    my $utf8enc = '';

    eval {
        $utf8enc    = Encode::encode('UTF-8', $string, Encode::FB_CROAK);
    };

    if ( $@ ) {
        $utf8enc    = '';
        my @chars   = split(//, $string);
        foreach my $char (@chars) {
            my $utf8char    = eval {
                Encode::encode('UTF-8', $char, Encode::FB_CROAK)
            } or next;
            $utf8enc .= $utf8char;
        }
    }
    return $utf8enc;
}

=back

=cut


1;
