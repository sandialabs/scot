package Scot::Email::Responder::Event;

use strict;
use warnings;
use Try::Tiny;
use Data::Dumper;
use Module::Runtime qw(require_module compose_module_name);
use Moose;
extends 'Scot::Email::PFResponder';

has name => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => 'Dispatch',
);

has parsers => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    builder     => '_build_parsers',
);

sub _build_parsers {
    my $self                = shift;
    my @parser_class_names  = (qw(
        Scot::Email::Parser::PassThrough
    ));    
    my @parsers = ();
    foreach my $cname (@parser_class_names) {
        require_module($cname);
        push  @parsers, $cname->new({ env => $self->env });
    }
    return wantarray ? @parsers : \@parsers;
}

sub _build_max_workers {
    my $self        = shift;
    my $package     = __PACKAGE__;
    my $responder   = $self->get_config_value("responders", undef, undef);
    my $workers     = 1;
    if (defined $responder) {
        if (defined $responder->{workers} ) {
            $workers     = $responder->{workers};
        }
    }
    return $workers;
}

has create_method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'create_via_mongo',
);

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $action  = $href->{action};
    my $data    = $href->{data};
    my $log     = $self->env->log;

    $log->debug("[Wkr $$] Processing Dispatch $action");

    PARSE:
    foreach my $parser (@{$self->parsers}) {
        if ( $parser->will_parse($data) ) {
            my $dispatch        = $parser->parse_message($data);
            my $created_count   = $self->create_dispatch($dispatch);
            if ( $created_count ) {
                $log->debug("$created_count dispatch(es) created");
            }
            else {
                $log->error("failed to create alertgroup from ",
                            { filter => \&Dumper, value => $alertgroup });
                # try the next parser?
                # next PARSE;
            }
            last PARSE;
        }
        $log->warn(ref($parser)." will not parse this data");
    }
    $log->debug("[Wkr $$] Finished");
}

sub create_dispatch {
    my $self    = shift;
    my $data    = shift;
    my $method  = $self->create_method;

    return $self->$method($data);
}

sub create_via_mongo {
    my $self    = shift;
    my $data    = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');

    my $event   = $col->api_create({
        request => {
            json    => $data,
        }
    });

}

sub create_via_api {
    my $self    = shift;
    my $data    = shift;
    # TODO
}

1;
