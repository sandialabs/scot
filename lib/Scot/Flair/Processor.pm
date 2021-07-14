package Scot::Flair::Processor;

use Data::Dumper;
use HTML::Entities;
use Moose;

###
### the job of the processor is to pull the data from the Alertgroup or Entry
### and to Parse the data down to a set of strings that Extractor can work with
###

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has regexes => (
    is          => 'ro',
    isa         => 'Scot::Flair::Regex',
    required    => 1,
);

has scotio  => (
    is          => 'ro',
    isa         => 'Scot::Flair::Io',
    required    => 1,
);

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Flair::Extractor',
    required    => 1,
);

sub flair {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->env->log;

    $log->info("-------- BEGIN FLAIR -------");


    my $timer   = $self->env->get_timer("flair_time");
    my $object  = $self->retrieve($data);
    if ( defined $object ) {
        my $results = $self->flair_object($object);
        $self->process_results($results);
    }
    else {
        $self->env->log->error("Unable to retrieve object ",
            {filter=>\&Dumper, value => $data});
    }
    &$timer;
    $log->info("-------- END FLAIR -------");
}

sub process_results {
    my $self    = shift;
    my $results = shift; # bug, hash in entry array in alertgroup
    my $io      = $self->scotio;
    my %stats   = ();
    my %notices = ();

    foreach my $result (@$results) {
        my $alert_id    = $result->{alert};
        my $ag_id       = $result->{alertgroup};
        if ($io->update_alert($result)) {

            $stats{alert}{$alert_id}++;
            $stats{alertgroup}{$ag_id}++;
            $notices{alert}{$alert_id}++;
            $notices{alertgroup}{$ag_id}++;

            foreach my $type ( keys %{ $result->{entities} }) {
                foreach my $value ( keys %{ $result->{entities}->{$type} } ) {
                    $notices{entity}{$value}++;
                }
            }
        }
        if (my $eid = $io->upsert_entities($result)) {
            $stats{entity}{$eid}++;
        }
    }
    $self->update_stats(\%stats);
    $self->send_notices(\%notices);
}


sub update_stats {
    my $self    = shift;
    my $stats   = shift;
    my $io      = $self->scotio;

    foreach my $type (keys %$stats) {
        foreach my $id (keys %{$stats->{$type}}) {
            $io->put_stat("$type flaired", 1);
        }
    }
}

sub send_notices {
    my $self    = shift;
    my $notices = shift;
    my $io      = $self->scotio;

    foreach my $type (keys %$notices) {
        foreach my $id (keys %{$notices->{$type}}) {
            $io->send_update_notice($type, $id);
        }
    }
}

sub send_notifications {
    my $self    = shift;
    my $object  = shift;
    my $results = shift;
    my $io      = $self->scotio;
    my $type = $self->get_type($object);

    $self->env->log->debug("RESULTS=",{filter=>\&Dumper, value=>$results});

    # need to send message to /queue/enricher for each entity

    my $agid    = $object->id;

    foreach my $href ( @$results ) {
        foreach my $entity ( @{ $href->{entities} } ) {
            my $entityid    = $io->get_entity_id($entity);
            if ( ! defined $entityid ) {
                # create the entity
                $entityid = $io->create_entity($entity, $agid, $href->{alert});
            }
            if ( defined $entityid ) {
                $io->send_mq('/queue/enricher',{
                    action  => 'updated',
                    data    => {
                        type    => 'entity',
                        id      => $entityid,
                        who     => 'scot-flair',
                    },
                });
            }
            else {
                $self->env->log->error("Entity $entity->{value} $entity->{type} not found, enricher queue message not sent!");
            }

        }
    }

    $io->send_mq("/topic/scot", {
        action  => 'updated',
        data    => {
            type    => $type,
            id      => $object->id,
        },
    });
}

sub get_type {
    my $self    = shift;
    my $object  = shift;
    my @parts   = split(/::/,ref($object));
    return lc($parts[-1]);
}

sub retrieve {
    my $self    = shift;
    my $data    = shift;
    my $log     = $self->env->log;
    my $io      = $self->scotio;
    my $type    = $data->{data}->{type};
    my $id      = $data->{data}->{id} + 0;

    $log->debug("[$$] worker retrieving $type $id");

    return $self->scotio->get_object($type, $id);
}

sub process_html {
    my $self    = shift;
    my $html    = shift;
    my $lid     = shift // '';
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("process_html");

    my %edb = (
        # entities => [],
        # flair    => '<flair html>',
        # text     => 'plain text representation'
    );

    my $cleanhtml   = $self->clean_html($html);
    my $tree        = $self->build_html_tree($cleanhtml);

    $self->walk_tree($lid, $tree, \%edb);

    $edb{text} = $self->generate_plain_text($tree);
    $edb{flair}= $self->generate_new_html($tree);

    $tree->delete;  # help prevent potential memory leaks

    my $elapsed = &$timer;
    $log->info("$lid Elapsed time to process ".length($cleanhtml)." characters: $elapsed");
    $log->trace("$lid EDB =",{filter=>\&Dumper, value=>\%edb});

    return \%edb;
}

sub clean_html {
    my $self    = shift;
    my $html    = shift;
    my $clean   = (utf8::is_utf8($html)) ?
                    Encode::encode_utf8($html) :
                    $html;
    if ($clean !~ /^<.*>/ ) { # if doesn't start with a <tag>, not the best test but...
        # wrap in div and encode html entities (latter may cause problems for some matches)
        $clean = '<div>'.
                 # encode_entities($clean, '<>').
                 $clean .
                 '</div>';
    }
    return $clean;
}

sub build_html_tree {
    my $self    = shift;
    my $html    = shift;
    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($html);
       $tree    ->elementify;
    return $tree;
}

sub generate_plain_text {
    my $self    = shift;
    my $tree    = shift;
    my $fmt     = HTML::FormatText->new();
    my $text    = $fmt->format($tree);
    return $text;
}

sub generate_new_html {
    my $self    = shift;
    my $tree    = shift;
    my $body    = $tree->look_down('_tag', 'body');
    my $div     = HTML::Element->new('div');
    $div->push_content($body->detach_content);
    my $new     = $div->as_HTML();
    return $new;
}
sub walk_tree {
    my $self    = shift;
    my $lid     = shift;
    my $element = shift;
    my $edb     = shift;
    my $level   = shift;
    my $extractor   = $self->extractor;
    my $log     = $self->env->log;

    $level += 1;
    my $spaces = $level * 4;
    $self->trace_decent($lid, $element, $spaces);

    if ( $element->is_empty ) {
        $log->trace($lid." "x$spaces."---- empty node ----");
        return;
    }

    $element->normalize_content;            # concats adjacent text nodes
    my @content = $element->content_list;   # get children (elements and text)
    my @new     = ();                       # hold the newly flaired content

    for (my $index = 0; $index < scalar(@content); $index++ ) {

        $log->trace($lid." "x$spaces."Index $index");

        if ( $self->is_not_leaf_node($content[$index]) ) {
            my $child   = $content[$index];

            # splunk likes to write ipaddrs (ip4 and ip6) in a "special" way
            # this will fix them so the flair engine can detect
            $self->fix_weird_html($child);

            # if this is userdefined flair, no further work is necessary
            if ( ! $self->user_defined_entity_element($child, $edb) ) {
                $log->trace($lid." "x$spaces."Element ".$child->address." found, recursing.");
                $self->walk_tree($lid, $child, $edb, $level);
            }
            # push the possibly modified copy of the child onto the new stack
            push @new, $child;
        }
        else {
            # leaf node case, start parsing the text
            my $text = $content[$index];
            $log->trace($lid." "x$spaces."Leaf Node content = ".$text);
            push @new, $extractor->parse($lid, $edb, $text);
        }
    }
    # replace the content of the element
    $element->splice_content(0, scalar(@content), @new);
}

sub is_not_leaf_node {
    my $self    = shift;
    my $node    = shift;
    return ref($node);
}

sub user_defined_entity_element {
    my $self    = shift;
    my $node    = shift;
    my $edb     = shift;

    my $tag = $node->tag;
    return undef if ($tag ne "span");

    my $class = $node->attr('class') // '';
    return undef if ( ! $self->external_defined_entity_class($class) );

    my $type    = $node->attr('data-entity-type');
    my $value   = $node->attr('data-entity-value');
    return undef if ( ! defined $type or ! defined $value);

    $self->extractor->add_entity($edb, $value, $type);
    $node->attr('class', "entity $class");
    return 1;
}

sub external_defined_entity_class {
    my $self    = shift;
    my $class   = shift;
    return undef if ( ! defined $class);
    my @permitted = (qw(userdef ghostbuster));
    return grep {/$class/} @permitted;
}

sub fix_weird_html {
    my $self    = shift;
    my $node    = shift;
    my $log     = $self->env->log;

    # splunk likes to wrap ipaddrs in a "special" way.  Undo the damage.

    my @content = $node->content_list;
    return if ( $self->fix_splunk_ipv4($node, @content));
    return if ( $self->fix_splunk_ipv6($node, @content));
}

sub fix_splunk_ipv4 {
    my $self    = shift;
    my $child   = shift;
    my @content = @_;
    my $found   = 0;
    my $log     = $self->env->log;

    for (my $i = 0; $i < scalar(@content) - 6; $i++) {
        if ( $self->has_splunk_ipv4_pattern($i, @content) ) {
            my $new_ipaddr = join('.',
                $content[$i]->as_text,
                $content[$i+2]->as_text,
                $content[$i+4]->as_text,
                $content[$i+6]->as_text);
            $child->splice_content($i, 7, $new_ipaddr);
            $found++;
        }
    }
    return $found;
}

sub has_splunk_ipv4_pattern {
    my $self    = shift;
    my $i       = shift;
    my @c       = @_;
    my $log     = $self->env->log;

    return undef if ( ! ref($c[$i]) );

    $log->trace("c[$i] = ".$c[$i]->tag);
    $log->trace("c[$i+6] = ".$c[$i]->tag);

    return undef if ( $c[$i]->tag   ne 'em');
    return undef if ( $c[$i+1]      ne '.');
    return undef if ( $c[$i+2]->tag ne 'em');
    return undef if ( $c[$i+3]      ne '.');
    return undef if ( $c[$i+4]->tag ne 'em');
    return undef if ( $c[$i+5]      ne '.');
    return undef if ( $c[$i+6]->tag ne 'em');
    return 1;
}

sub fix_splunk_ipv6 {
    my $self    = shift;
    my $child   = shift;
    my @content = @_;
    my $found   = 0;

    for (my $i = 0; $i < scalar(@content) - 8; $i++) {
        if ( $self->has_splunk_ipv4_pattern($i, @content) ) {
            my $new_ipaddr = join('.',
                $content[$i]->as_text,
                $content[$i+2]->as_text,
                $content[$i+4]->as_text,
                $content[$i+6]->as_text,
                $content[$i+7]->as_text,
                $content[$i+8]->as_text);
            $child->splice_content($i, 7, $new_ipaddr);
            $found++;
        }
    }
    return $found;
}

sub has_splunk_ipv6_pattern {
    my $self    = shift;
    my $i       = shift;
    my @c       = @_;

    return undef if ( ! ref($c[$i]) );
    return undef if ( $c[$i]->tag   ne 'span');
    return undef if ( $c[$i+1]      ne ':');
    return undef if ( $c[$i+2]->tag ne 'span');
    return undef if ( $c[$i+3]      ne ':');
    return undef if ( $c[$i+4]->tag ne 'span');
    return undef if ( $c[$i+5]      ne ':');
    return undef if ( $c[$i+6]->tag ne 'span');
    return undef if ( $c[$i+7]      ne '0:0:0' and
                      $c[$i+7]      !~ /([0-9a-f]{1,4}:){3}/i );
    return undef if ( $c[$i+8]->tag ne 'span');
    return 1;
}


sub trace_decent {
    my $self    = shift;
    my $lid     = shift;
    my $element = shift;
    my $spaces  = shift;
    my $log     = $self->env->log;
    $log->trace($lid." "x$spaces . "Walking Node: ".$element->starttag." (".$element->address.")");
}


sub genspan {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;

    return  qq|<span class="entity $type" |.
            qq| data-entity-value="$value" |.
            qq| data-entity-type="$type">$value</span>|;
}

1;
