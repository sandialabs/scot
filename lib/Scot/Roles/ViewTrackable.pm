package Scot::Roles::ViewTrackable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

requires 'log';

=item C<viewed_by>
 array of the view records that have viewed this alert
 {
    user => {
        when =>
        count =>
        from =>
    }
}
=cut
has viewed_by   => (
    is          =>  'rw',
    traits      =>  [ 'Hash' ],
    isa         =>  'HashRef',
    required    =>  1,
    builder     =>  '_build_viewed_by',
    handles     =>  {
        set_view_record     => 'set',
        get_view_record     => 'get',
        has_no_views        => 'is_empty',
        delete_view_record  => 'delete',
        users_who_viewed    => 'keys',
        clear_view_record   => 'clear',
        all_view_records    => 'kv',
        team_view_count          => 'count',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_col_name    => 'views',
        alt_data_sub    => 'views',
    },
);

has view_count  => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

sub add_view_count {
    my $self    = shift;
    my $vc      = $self->view_count;
    $self->view_count($vc+1);
}


sub views {
    my $self    = shift;
    return $self->view_count();
}


sub _build_viewed_by {
    my $self    = shift;
    return {};
}

sub total_views {
    my $self    = shift;
    my $total   = 0; 
    for my $kv ( $self->all_view_records ) {
        my $lc = $kv->[1]->{count} + 0;
        $total += $lc;
    }
    return $total;
}

sub get_view_hash {
    my $self    = shift;
    my $href    = {};

    for my $kv ($self->all_view_records) {
        my $user = $kv->[0];
        my $ref  = $kv->[1];
        $href->{$user} = $ref;
    }
    return $href;
}

sub add_view_record {
    my $self    = shift;
    my $env     = shift;
    my $who     = shift;
    my $where   = shift;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $when    = time();

    $log->trace("Adding view record");

    my $count   = $self->viewed_by->{$who}->{count} // 0;
    $count++;
    my $view_href    = {
        count   => $count,
        when    => $when,
        from    => $where,
    };
    $self->set_view_record( $who => $view_href ) ;
    # $self->add_view_count();
    $mongo->update_document($self);
}


1;

