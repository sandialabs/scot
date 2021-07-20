package Scot::Email::Processor;

use strict;
use warnings;

=head1 Scot::Email::Processor;

base class for processors

=cut
use lib '../../../lib';
use utf8;
use Scot::Email::Imap;
use Moose;
extends 'Scot::App';

has mbox    => (
    is      => 'ro',
    isa     => 'HashRef',
    required=> 1,
);

has imap    => (
    is      => 'ro',
    isa     => 'Scot::Email::Imap',
    required => 1,
    lazy    => 1,
    builder => '_build_imap',
);

sub _build_imap {
    my $self    = shift;
    my $mbox    = $self->mbox;
    my $imap_config = $mbox->{imap};
    $imap_config->{env}  = $self->env;
    $imap_config->{test} = $mbox->{test};
    my $imap        = Scot::Email::Imap->new($imap_config);
    return $imap;
}

has peek_mode => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    builder     => '_build_peek_mode',
);

sub _build_peek_mode {
    my $self    = shift;
    my $mbox    = $self->mbox;

    if ( defined $mbox->{test} && $mbox->{test} == 1 ) {
        return 1;
    }
    if ( defined $mbox->{peek} && $mbox->{peek} == 1 ) {
        return 1;
    }
    return 0;
}

has dry_run => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

sub run {
    my $self    = shift;
    my $mbox    = $self->mbox;
    my $imap    = $self->imap;
    my $cursor  = $imap->get_mail($mbox);
    my $count   = $cursor->count;
    my $log     = $self->env->log;

    $log->debug("[$mbox->{name}] Found $count messages");

    my $index = 1;
    while ( my $message = $cursor->next ) {
        $log->debug("Processing message $index of $count");
        if ( ! $self->process_message($message) ) {
            $imap->mark_uid_unseen($message->{imap_uid});
        }
        $index++;
    }
}

sub get_tlp {
    my $self    = shift;
    my $data    = shift;
    my $parent  = shift;
    my $log     = $self->env->log;

    my @valid   = (qw(amber black green red unset white));

    my $tlp = $data->{tlp};
    if (defined $tlp and $tlp ne "" and grep {/$tlp/} @valid ) {
        $log->trace("found tlp in data = $tlp");
        return  $tlp;
    }

    $tlp = $parent ->tlp;
    if (defined $tlp and $tlp ne "" and grep {/$tlp/} @valid ) {
        $log->trace("found tlp from dispatch = $tlp");
        return  $tlp;
    }
    $log->trace("tlp not found, using unset");

    $tlp = 'unset';
    return $tlp;
}

1;
