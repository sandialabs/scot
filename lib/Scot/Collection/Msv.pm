package Scot::Collection::Msv;

use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

# tags can be created from a post to /scot/v2/tag
# ( also "put"ting a tag on a thing will create one but not in this function

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    $log->trace("Create Msv from API");
    $log->debug("request is ",{ filter=>\&Dumper, value=>$request });

    my $json    = $request->{request}->{json};

    my $value       = lc($json->{message_id});

    unless ( defined $value ) {
        $log->error("Error: must provide the message_id as the value param");
        return { error_msg => "No MSV message_id provided" };
    }

    my $msv_obj         = $self->find_one({ message_id => $value });

    unless ( defined $msv_obj ) {
        my $href    = { message_id => $value };
        $msv_obj    = $self->create($href);
    }

    return $msv_obj;
};

override api_list   => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    $log->debug("msv api_list");

    my $msgid   = $request->{request}->{params}->{message_id};
    my $query   = { message_id => $msgid };
    my $cursor  = $self->find($query);
    my $total   = $self->count($query);

    return ($cursor, $total);
};


1;

