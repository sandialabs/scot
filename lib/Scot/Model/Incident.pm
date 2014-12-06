package Scot::Model::Incident;

use lib '../../lib';
use strict;
use warnings;
use v5.10;
use Data::Dumper;
use Switch;
use Date::Parse;
use DateTime;
use DateTime::Format::Natural;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Incidents - a moose obj rep of a Scot Incident

=head1 DESCRIPTION

 Definition of an Incident

=cut

extends 'Scot::Model';
enum 'valid_status', [ qw( open closed ) ];

with (
    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Entriable',
    'Scot::Roles::Entitiable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Permittable',
    'Scot::Roles::Ownable',
    'Scot::Roles::SetOperable',
    'Scot::Roles::Sourceable',
    'Scot::Roles::Taggable',
);

=item C<incident_id>

 the integer id of the incident

=cut

has incident_id => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<idfield>

 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...

=cut

has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'incident_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'incidents',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<events>

 array of alert_id's that make up the incident

=cut

has events      => (
    is          => 'rw',
    isa         => 'ArrayRef[Int]',
    traits      => [ 'Array' ],
    builder     => '_build_empty_array',
    handles     => {
        add_event   => 'push',
        add_events  => 'push',
        all_events  => 'elements',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<reportable>

 an incident is reportable if meeting  requirements
 but an incident can also encapsulate several "events" into a cluster
 a non-reportable incident would not need to be tracked for compliance

=cut

has reportable  => (
    is          => 'rw',
    isa         => 'Bool',
    traits      => ['Bool'],
    required    => 0,
    default     => 1, 
    handles     => {
        make_reportable            => 'set',
        make_not_reportable        => 'unset',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);


=item C<occurred, discovered, reported>

 integer time values
 
=cut

has [qw(occurred discovered reported)] => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);

=item C<subject>

 string describing incident

=cut

has subject => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1,
    },
);

=item C<status>

 the status

=cut

has status      => (
    is          => 'rw',
    isa         => 'valid_status',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<type>

 the  type

=cut

has type    => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    required    => 1,
    default     => "Type 2",
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<category>


=cut

has category => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => 'none',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<sensitivity>


=cut

has sensitivity => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    required    => 1,
    default     => "Other",
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<affected>

 number of systems affected

=cut

has affected => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 1,
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<critical_infrastructure>

is this critical infrastructure?

=cut

has critical_infrastructure => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<security_category>


=cut

has security_category => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => "Low",
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item reporting_deadline

 1. met
 2. missed
 3. future
 4. no deadline
 5. error

=cut

has reporting_deadline => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    lazy        => 1,
    builder     => 'met_reporting_deadline',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<files>

    Array of file_ids 

=cut

has files   => (
    is          => 'rw',
    isa         => 'ArrayRef[Int]',
    traits      => [ 'Array' ],
    builder     => '_build_empty_array',
    handles     => {
        add_files   => 'push',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);


around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;
    
    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        
        my $req         = $_[0]->req;
        my $json        = $req->json;
        my @tags        = $json->{'tag'};
        my $occurred    = $class->numberfy($json->{'occurred'});
        my $discovered  = $class->numberfy($json->{'discovered'});
        my $reported    = $class->numberfy($json->{'reported'});
        my $subject     = $json->{'subject'};
        my $status      = $json->{'status'} // 'open';
        my $type        = $json->{'type'};
        my $category    = $json->{'category'};
        my $sensitivity = $json->{'sensitivity'};
        my $affected    = $class->numberfy($json->{'affected'});
        my $critical_infrastructure = $json->{'critical_infrastructure'};
        my $security_category       = $json->{'security_category'};
        my $href    = {
            tags        => \@tags,
            occurred    => $occurred,
            discovered  => $discovered,
            reported    => $reported,
            subject     => $subject,
            status      => $status // 'open',
            type        => $type,
            category    => $category,
            sensitivity => $sensitivity,
            affected    => $affected,
            critical_infrastructure => $critical_infrastructure,
            security_category       => $security_category,
            env         => $_[0]->env,
        };
        my $rg  = $json->{'readgroups'};
        my $mg  = $json->{'modifygroups'};

        $href->{readgroups}     = $rg if ( scalar(@$rg) > 0);
        $href->{modifygroups}   = $mg if ( scalar(@$mg) > 0);
        if ( $json->{'created'} ) {
            $href->{created} = $json->{'created'};
        }

        return $class->$orig($href);
    }
    else {
        return $class->$orig(@_);
    }
};

sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received " . Dumper($json));

    while ( my ($k, $v) = each %$json ) {
        if ( $k eq "cmd" ) {
            # do stuff 
            if ($v eq "addtag") {
                foreach my $tag (@{$json->{tag}}) {
                    $self->add_tag($tag);
                    push @$changes, "Added Tag: $tag";
                }
            }
            if ($v eq "rmtag") {
                foreach my $tag (@{$json->{tag}}) {
                    $self->remove_tag($tag);
                    push @$changes, "Removed Tag: $tag";
                }
            }
        }
        else {
            next if ( $k eq "tag" );
            $log->debug("update $k to $v");
            my $orig    = $self->$k;
            $self->$k($v);
            push @$changes, "Changed $k from $orig to $v";
        }
    }
    $self->updated($now);
    $self->add_historical_record({
        who     => $user,
        when    => $now,
        what    => $changes,
    });
}

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data_href = {};

    while ( my ($k, $v) = each %$json ) {
        if ($k eq "cmd") {
            if ($v  eq "addtag" ) {
                $data_href->{'$addToSet'}->{tags}->{'$each'} = $json->{tags};
                push @$changes, "added tag(s): ". join(', ', @{$json->{tags}});
            }
            if ($v  eq "rmtag" ) {
                $data_href->{'$pullAll'}->{tags} = $json->{tags};
                push @$changes, "removed tag(s): ". join(', ', @{$json->{tags}});
            }
        }
        else {
            next if ($k eq "tags") ;
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, "updated $k from $orig";
                $data_href->{'$set'}->{$k} = $v;
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data_href->{'$set'}->{updated} = $now;
    $data_href->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => join(', ', @$changes),
    };
    my $modhref = {
        collection  => "incidents",
        match_ref   => { incident_id   => $self->incident_id },
        data_ref    => $data_href,
    };
    return $modhref;
}

sub _build_empty_array {
    return [];
}

sub get_due_date_delta {
    my $self    = shift;
    my $type        = $self->type;
    my $sensitivity = $self->sensitivity;
    my $sec_cat     = $self->security_category;
    my $category    = $self->category;
    my $delta       = DateTime::Duration->new(seconds=>0);
    my $log         = $self->log;

    $log->debug("calculating due delta for $type, $sensitivity, $sec_cat, $category");

    if ( $sensitivity eq "PII" ) {
        return DateTime::Duration->new(minutes => 35);
    }

    if ( $category ne "none" ) { # IMI-x trumps all
        if ($category =~ m/1/) {
            $delta  = DateTime::Duration->new(hours=>1);
        }
        else {
            $delta  = DateTime::Duration->new(hours=>8);
        }
    }
    else {
        if ($type   =~ m/1/) { # Type 1: Information Compromise
            switch ($sec_cat) {
                case 'Low' {
                    $delta = DateTime::Duration->new(hours=>4);
                }
                case 'Moderate' {
                    $delta = DateTime::Duration->new(hours=>1);
                }
                case 'High' {
                    $delta = DateTime::Duration->new(hours=>1);
                }
            }
        }
        elsif ( $type =~ m/2/) { # Type 2: 
            switch ($sec_cat) {
                case 'Low'  {
                    $delta  = DateTime::Duration->new(weeks=>1);
                }
                case 'Moderate' {
                    $delta  = DateTime::Duration->new(hours=>24);
                }
                case 'High' {
                    $delta  = DateTime::Duration->new(hours=>24);
                }
            }
        }
    }
    
    return $delta;
}

sub met_reporting_deadline {
    my $self        = shift;
    my $log         = $self->log;
    my $type        = $self->type;
    my $discovered  = $self->discovered;
    my $reported    = $self->reported;
    my $complete    = "yes";

    unless ($reported) {
        $complete = "no";
        $reported = $self->_timestamp();
    }

    my $discovered_dt   = DateTime->from_epoch( epoch => $discovered );
    my $reported_dt     = DateTime->from_epoch( epoch => $reported );
    my $delta           = $self->get_due_date_delta();

    $log->debug("$delta is ".ref($delta));

    my $due_dt  = $discovered_dt + $delta;

    if ($type =~ m/FYI|^Other/ or $delta->is_zero()) {
        return "no deadline";
    }

    if (ref($due_dt) ne "DateTime") {
        $log->error("Error Calculating Due Date!");
        return "error";
    }

    if (DateTime->compare($due_dt,$reported_dt) >= 0) {
        $log->debug("reporting deadline met or still in future");
        if ($complete eq "yes") {
            return "met";
        }
        else {
            return "future";
        }
    }
    return "missed";
}

sub get_self_collection {
    return "incidents";
}

sub remove_self_from_references {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;
    my $idfield     = $self->idfield;
    my $id          = $self->$idfield;
    my $thiscollection  = 'incidents';
    my $match_ref   = { $thiscollection => $id };
    my $data_ref    = { '$pull' => { $thiscollection => $id } };
    my $opts_ref    = { multiple => 1, safe => 1 };

    foreach my $collection (qw(events)) {
        if ( $mongo->apply_update({
            collection  => $collection,
            match_ref   => $match_ref,
            data_ref    => $data_ref,
        }, $opts_ref) ) {
            $log->debug("removed $thiscollection  $id ".
                        "references from $collection");
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
