package Scot::Domain;

use strict;
use warnings;
use Moose;
use experimental 'signatures';
no warnings 'experimental';
use Data::Dumper;
use Module::Runtime qw(require_module);
use Log::Log4perl qw(get_logger);
use lib '../../lib';
use Scot::Client::Messageq;
use Scot::Types;

has log => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    required=> 1,
    builder => '_build_log',
);

sub _build_log ($self) {
    my $log = get_logger('Scot');
    return $log;
}

has mongo   => (
    is      => 'ro',
    isa     => 'Meerkat',
    required=> 1,
);

has collection  => (
    is          => 'ro',
    isa         => 'ScotCollection',
    required    => 1,
    lazy        => 1,
    builder     => '_build_collection', # implemented in subclasses
);

has mq      => (
    is      => 'ro',
    isa     => 'Scot::Client::Messageq',
    lazy    => 1,
    required=> 1,
    default => sub { Scot::Client::Messageq->new },
);

has skipfields  => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [qw(sort columns limit offset withsubject)] },
);

has taglikefields   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [qw(tag source)] },
);

has exactfields => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [qw(status)] },
);

has permittables => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [
        qw(
            alertgroup alert checklist entry event file 
            guide incident intel signature dispatch product
        )
    ] },
);

sub get_related_domain ($self, $name) {
    my $class = "Scot::Domain::".ucfirst($name);
    require_module($class);
    return $class->new({mongo => $self->mongo});
}


sub build_mongo_query ($self, $request) {
    my $query   = {};
    my $log     = $self->log;
    my $params  = $request->{data}->{params};
    my $datefields  = $self->datefields;

    foreach my $key (%$params) {
        my $value   = $params->{$key};
        if ( $self->is_date_field($key) ) {
            $query->{$key} = $self->parse_datefield_match($value);
        }
        elsif ( $self->is_handler_time_field($key) ) {
            $query->{$key} = ($key eq "start") ? 
                { '$gte' => $value } :
                { '$lte' => $value };
        }
        elsif ( $self->is_numeric_field($key) ) {
            $query->{$key} = $self->parse_numericfield_match($value);
        }
        elsif ( $self->is_taglike_field($key) ) {
            $query->{$key} = $self->parse_taglike_match($value);
        }
        elsif ( $self->is_exact_match_field($key) ) {
            $query->{$key} = $self->parse_exact_match($value);
        }
        else {
            if ( $self->is_value_numeric($value) ) {
                $query->{$key} = $self->parse_numericfield_match($value);
            }
            else {
                $query->{$key} = $self->parse_stringfield_match($value);
            }
        }
    }
    my $projection  = $self->build_projection($request);
    my $limit       = $self->build_limit($request);
    my $skip        = $self->build_offset($request);
    my $sort        = $self->build_sort($request);

    my $options = {};

    $options->{limit}       = $limit if ($limit);
    $options->{projection}  = $projection if ($projection);
    $options->{skip}        = $skip if ($skip);
    $options->{sort}        = $sort if ($sort);
        
    $log->trace("Query = ",{filter => \&Dumper, value => $query});
    return $query, $options;
}

sub is_date_field ($self, $fieldname) {
    my $fields  = $self->datefields;
    return grep {/$fieldname/} @$fields;
}

sub is_handler_time_field ($self, $fieldname) {
    my $fields  = $self->handler_time_fields;
    return grep {/$fieldname/} @$fields;
}

sub is_numeric_field ($self, $fieldname) {
    my $fields  = $self->numfields;
    return grep {/$fieldname/} @$fields;
}

sub is_taglike_field ($self, $fieldname) {
    my $fields  = $self->taglikefields;
    return grep {/$fieldname/} @$fields;
}

sub is_exact_match_field ($self, $fieldname) {
    my $fields  = $self->exactfields;
    return grep {/$fieldname/} @$fields;
}

sub is_value_numeric ($self, $value) {
    return $value =~ /^\d+$/;
}

sub build_sort ($self, $request) {
    my @s   = ();

    my $sort_ref = $request->{data}->{params}->{sort};

    if ( defined $sort_ref ) {
        if (ref($sort_ref) ne "ARRAY" ) {
            $sort_ref = [ $sort_ref ];  # turn scalar into an array
        }
        foreach my $term (@$sort_ref) {
            if ( $term =~ /^-(\S+)$/ ) { # one or more word char preceded by -
                push @s, $1, -1;         # mongo drive require an ordered doc (array)
            }
            elsif ( $term =~ /^\+(\S+)$/ ) { # preceded by a +
                push @s, $1, 1;
            }
            else {  # default is +
                push @s, $term, 1;
            }
        }
    }
    return wantarray ? @s : \@s;
}

sub build_limit ($self, $request) {
    my $limit       = undef;
    my $limit_req   = $request->{data}->{params}->{limit};
    if (defined $limit_req) {
        if ( $self->is_value_numeric($limit_req) ) {
            $limit = $limit_req;
        }
    }
    return $limit;
}

sub build_projection ($self, $request) {
    my %projection  = ();
    my $columns = $request->{data}->{params}->{columns};

    if ( defined $columns and ref($columns) eq "ARRAY" ) {
        foreach my $col (@$columns) {
            $projection{$col} = 1;
        }
        if ( scalar(keys %projection) != 0 ) {
            return wantarray ? %projection : \%projection;
        }
    }
    return undef;
}

sub build_offset ($self, $request) {
    my $skip    = 0;
    my $reqskip = $request->{data}->{params}->{offset};
    if ( $reqskip =~ /^\d+$/ ) {
        $skip = $reqskip;
    }
    return $skip;
}

sub get_array_from_request_data ($self, $json, $key) {
    my @tags    = ();
    if ( defined $json->{$key} ) {
        if ( ref($json->{$key}) eq "ARRAY" ) {
            push @tags, @{$json->{$key}};
        }
        else {
            push @tags, $json->{$key};
        }
    }
    return wantarray ? @tags : \@tags;
}

sub validate_permissions ($self, $json, $target) {
    my $env     = $self->env;
    my $log     = $env->log;
    my $type    = lc((split(/::/, ref($self)))[-1]);

    if ( grep {/$type/} @{$self->permittables} ) {
        my $default_perms = $self->get_default_perms($target);
        return $default_perms;
    }
    else {
        $log->trace("type $type does not have permissions, no validation necessary");
    }
    return undef;
}

sub get_default_perms ($self, $target) {
    my $env = $self->env;

    if ( defined $target) {
        return $self->get_target_permissions($target);
    }
    return $env->default_groups;
}

sub get_target_permisions ($self, $target) {
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $type    = $target->{type};
    my $id      = $target->{id};

    my $groups  = $env->default_groups;

    if ( defined $type and defined $id ) {
        my $object  = $mongo->collection(ucfirst($type))->find_iid($id);
        if ( defined $object ) {
            if ( $object->meta->does_role('Scot::Role::Permission') ) {
                my $targetgroups = $object->groups;
                if (defined $targetgroups ) {
                    $groups = $targetgroups;
                }
            }
        }
    }
    return $groups;
}

sub tag_source_bookkeep ($self, $object) {
    my @results     = ();
    my $appearance  = $self->get_related_domain('appearance');

    foreach my $type (qw(tag source)) {
        my $domain  = $self->get_related_domain($type);
        my $aref    = $object->$type;
        $aref = [$aref] if (ref($aref) ne "ARRAY");
        foreach my $ts (@$aref) {
            my $tsobj = $domain->upsert($ts);
            my $apobj = $appearance->create_ts_appearance(
                $type, $ts, $tsobj, $object
            );
        }
    }
}

sub get_object_type ($self, $object) {
    return lc((split(/::/,ref($object)))[-1]);
}

sub send_mq ($self, $msgs) {
    my $mq  = $self->env->mq;
    if (ref($msgs) ne "ARRAY") {
        $msgs = [ $msgs ];
    }
    foreach my $m (@$msgs) {
        my $queues = $m->{queues};
        my $data   = $m->{message};
        foreach my $q (@$queues) {
            $mq->send($q, $data);
        }
    }

}

sub extract_owner ($self, $request, $default=undef) {
    my $owner   = $request->{owner};
    if ( ! defined $owner ) {
        if ( defined $default ) {
            return $default;
        }
        return 'unknown';
    }
    return $owner;
}

sub amq_send_create ($self, $collection, $id, $who) {
    $self->mq->send('/topic/scot', {
        action  => 'created',
        data    => {
            type    => $collection,
            id      => $id,
            who     => $who,
        }
    });
}
    

1;
