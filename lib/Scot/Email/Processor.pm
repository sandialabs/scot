package Scot::Email::Processor;

use strict;
use warnings;

=head1 Scot::Email::Processor;

base class for processors

=cut

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
        $self->process_message($message);
        $index++;
    }
}

1;
