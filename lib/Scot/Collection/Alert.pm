package Scot::Collection::Alert;
use lib '../../../lib';
use v5.18;
use Moose 2;
use MooseX::AttributeShortcuts;
use Type::Params qw/compile/;
use Types::Standard qw/slurpy :types/;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_handler {
    return {
        error   => "Direct creation of Alerts from Web API not supported",
    };
}

# updating an Alert can cause changes in the alertgroup

override 'update'   => sub {
    state $check    = compile( Object, Object, HashRef );
    my ( $self,
         $obj,
         $update )  = $check->(@_);

    my $data        = $self->_try_mongo_op(
        update  => sub {
            $self->_mongo_collection->find_and_modify({
                query   => { _id    => $obj->_id },
                update  => $update,
                new     => 1,
            });
    },);

    if ( ref $data ) {
        $self->_sync( $data => $obj );
        ## doing this manually in Scot::Collection::Event::build_from_alerts
        # alert has synced to database
        # update the alertgroup data
        $self->update_alertgroup_data($obj);
        return 1;
    }
    else {
        $obj->_set_removed(1);
        return;
    }
};

sub update_alertgroup_data {
    my $self    = shift;
    my $obj     = shift;
    my $mongo   = $self->env->mongo;

    my $alertgroup_id   = $obj->alertgroup;

    my $agcol   = $mongo->collection("Alertgroup");

    $agcol->refresh_data($alertgroup_id);

}

sub get_alerts_in_alertgroup {
    my $self    = shift;
    my $id      = shift;
    $id         += 0;       # argh! otherwise it tries string match
    my $cursor  = $self->find({alertgroup => $id});
    return $cursor;
}

1;
