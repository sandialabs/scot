package Scot::Email::Parser::EventApi;

use lib '../../../../lib';
use HTML::TreeBuilder;
use Data::Dumper;
use Moose;
extends 'Scot::Email::Parser';

=head1 Scot::Email::Parser::Event

replacement for the EmailApi2.pm
requires a "command" html table at top of email

=cut

sub get_sourcename {
    return "coe";
}

sub will_parse {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};
    my $body    = $href->{body_html};
    my $tree    = $self->build_html_tree($body);

    if (!$tree) {
        return undef;
    }

    my @basics = $self->extract_event_basics($tree);
    if (scalar(@basics) < 1) {
        return undef;
    }
    return 1;
}

sub parse_message {
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;

    $log->debug("Parsing SCOT Event email");

    my $body    = $self->normalize_body($message);
    my $tree    = $self->build_html_tree($body);

    if ( ! defined $tree ) {
        $log->error("Unable to parse message body!",
                    { filter => \&Dumper, value => $message });
        return undef;
    }

    my $command = $self->extract_command($message);
    my $from = $message->{from};
    my ($subject, $tags, $sources, $status) = $self->extract_event_basics($tree);

    if ( ! defined $subject ) {
        $subject    = $message->{subject};
    }

    if ( ! defined $status ) {
        $status = 'open';
    }


    $log->debug("SOURCES = ",{filter=>\&Dumper, value => $sources});

    my %json    = (
        command => $command,
        event   => {
            subject     => $subject,
            owner       => $from,
            tag         => $tags,
            source      => $sources,
            status      => $status,
            groups      => $self->env->default_groups,
        },
        entry   => {
            body    => $tree->as_HTML,
            groups  => $self->env->default_groups,
        }
    );

    return wantarray ? %json : \%json;
}

sub normalize_body {
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;
    my $body    = $message->{body_html};
    # add data norming here if necessary
    return $body;
}

sub extract_command { 
    my $self    = shift;
    my $message = shift;
    my $log     = $self->env->log;
    my $subject = $message->{subject};
    my @validcmd    = (qw(new update add));


    if ( defined $subject ) {
        (my $command = $subject) =~ s/\{(.*)\}/$1/;

        if ( grep {/$command/} @validcmd ) {
            return $command;
        }
    }
    return "new";
}

sub extract_event_basics {
    my $self    = shift;
    my $tree    = shift;
    my $log     = $self->env->log;
    my $subject;
    my $status;
    my $tags;
    my $sources;

    my $table   = ($tree->look_down('_tag','table'))[0];

    $table->detach();

    my @rows    = $table->look_down('_tag', 'tr');

    foreach my $row (@rows) {
        my @cells = $row->look_down('_tag', 'td');
        for ( my $i = 0; $i < scalar(@cells); $i += 2) {
            my $key;
            my $val;
            my $j   = $i+1;

            if ( defined $cells[$i] and ref($cells[$i]) eq "HTML::Element" ) {
                $key    = $cells[$i]->as_text;
            }
            if ( defined $cells[$j] and ref($cells[$j]) eq "HTML::Element" ) {
                $val    = $cells[$j]->as_text;
            }
            if (lc($key) eq "subject") {
                $subject = $val;
            }
            if (lc($key) eq "sources") {
                $sources = [ split(/[ ]*,[ ]*/,$val) ];
            }
            if (lc($key) eq "tags") {
                $tags    = [ split(/[ ]*,[ ]*/,$val) ];
            }
            if (lc($key) eq "status") {
                $status = $val;
            }
        }
    }
    return $subject, $tags, $sources, $status;
}


sub inline_images {
    my $self    = shift;
    my $email   = shift;
    my $tree    = shift;
    my $log     = $self->env->log;

    # now the hard stuff
    my $images  = $email->{attached_images};

    my @imgtags = $tree->look_down('_tag', 'img');
    foreach my $it (@imgtags) {
        my $src     = $it->attr('src');
        (my $name = $src) =~ s/cid:(.*)@.*/$1/;
        $log->debug("replacing $src img with $name");
        my $newimg  = $images->{$name};
        $it->replace_with($newimg);
    }
}


1;
