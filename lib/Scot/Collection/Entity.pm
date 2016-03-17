package Scot::Collection::Entity;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
    Scot::Role::GetTargeted
);

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mq      = $env->mq;

    $log->trace("Creating Entity via API");

    my $request = $href->{request}->{json};
    my $entity  = $self->create($request);

    unless ( defined $entity ) {
        $log->error("Error! Failed to create Entity with data ",
                    { filter => \&Dumper, value => $request } );
        return undef;
    }
    $env->mq->send("scot", {
        action  => "created",
        data    => {
            type    => "entity",
            id      => $entity->id,
        }
    });
    return $entity;
}


sub update_entities {
    my $self    = shift;
    my $target  = shift;    # Scot::Model Object
    my $earef   = shift;    # array of hrefs that hold entityinfo

    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $type    = $target->get_collection_name;
    my $id      = $target->id;
    my $linkcol = $mongo->collection('Link');

    $log->trace("[$type $id] Updating associated entities");
    
    # find entity or create it.

    foreach my $entity (@$earef) {
        my @command    = (
            findAndModify   => "entity",
            query           => { 
                value   => $entity->{value}, 
                type    => $entity->{type},
            },
            update          => {
                '$setOnInsert'  => {
                    value   => $entity->{value},
                    type    => $entity->{type},
                }
            },
            new     => 1,
            upsert  => 1,
        );

        my $return = $self->_try_mongo_op(
            find_or_create => sub {
                my $dbname  = $self->meerkat->database_name;
                my $db      = $self->meerkat->_mongo_database($dbname);
                my $job     = $db->run_command(\@command);
                return $job;
            }
        );

        $log->debug("FindAndModify returned: ",{ filter =>\&Dumper, value => $return });

        my $entity_id    = $return->{id};

        my $link    = $linkcol->create_link({
            type   => "entity",
            id     => $entity_id,
        },{
            type => $type,
            id   => $id,
        });
    }
}

1;
