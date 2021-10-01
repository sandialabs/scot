package Scot::Flair::Engine;

use strict;
use warnings;
use utf8;
use lib '../../../lib';

use Encode;
use Data::Dumper;
use Scot::Flair::Imgmunger;
use HTML::Entities;
use HTML::TreeBuilder;
use HTML::FormatText;
use SVG::Sparkline;
use Try::Tiny;
use Moose;


has env => (
    is       => 'ro',
    isa      => 'Scot::Env',
    required => 1,
);

has regexes => (
    is       => 'ro',
    isa      => 'Scot::Flair::Regex',
    required => 1,
);

has scotio  => (
    is       => 'ro',
    isa      => 'Scot::Flair::Io',
    required => 1,
);

has extractor => (
    is       => 'ro',
    isa      => 'Scot::Flair::Extractor',
    required => 1,
);


sub flair {
    my $self    = shift;
    my $message = shift;    # data from activemq
    my $log     = $self->env->log;

    $log->info("--- BEGIN --- FLAIR --- ENGINE ---");

    my $timer   = $self->env->get_timer("flair_time");
    my $object  = $self->scotio->retrieve($message);

    if ( defined $object ) {

        my $obj_type = ref($object);

        if ( $obj_type eq "Scot::Model::Entry" ) {
            $self->flair_entry($object);
        }
        elsif ( $obj_type eq "Scot::Model::Alertgroup" ) {
            $self->flair_alertgroup($object);
        }
        elsif ( $obj_type eq "Scot::Model::RemoteFlair") {
            $self->flair_remote_flair($object);
        }
        else {
            $log->error("Unsupported Flairable $obj_type!");
        }
        my $elapsed = &$timer;
        $log->info("TIME == $elapsed secs :: ".ref($object)."(".$object->id.")");
    }
    else {
        $log->error("Failed to retriev object from ", 
                    { filter => \&Dumper, value => $message });
    }
    $log->info("--- END --- FLAIR --- ENGINE ---");
}

sub flair_entry {
    my $self    = shift;
    my $entry   = shift;
    my $log     = $self->env->log;

    $log->info("---- Begin Flair Entry ---");

    my ($edb,
        $flair,
        $text)  = $self->extract_from_entry($entry);

    $self->scotio->update_entry($entry, $edb, $flair, $text);

    $log->info("---- End Flair Entry ---");
}

sub flair_remote_flair {
    my $self        = shift;
    my $remoteflair = shift;
    my $log     = $self->env->log;

    $log->info("---- Begin Flair RemoteFlair ---");

    my ($edb,
        $flair,
        $text)  = $self->extract_from_remoteflair($remoteflair);

    $self->update_remoteflair($remoteflair, $edb, $flair, $text);

    $log->info("---- End Flair RemoteFlair ---");
}

sub flair_alertgroup {
    my $self        = shift;
    my $alertgroup  = shift;
    my $log     = $self->env->log;

    $log->info("---- Begin Flair Alertgroup ---");

    $self->extract_from_alertgroup($alertgroup);
    $self->scotio->send_alertgroup_updated_message($alertgroup->id);

    $log->info("---- End Flair Alertgroup ---");
}

sub extract_from_entry {
    my $self    = shift;
    my $entry   = shift;
    my $log     = $self->env->log;
    my $scotio  = $self->scotio;
    my $html    = $self->get_entry_html($entry);

    my $edb     = {};   # extracted entities
    my $flair   = '';   # HTML with wrapped entities
    my $text    = '';   # plain text representation of entry

    if (defined $html) {
        my $tree = $self->build_html_tree($html);
        $text   = $self->generate_plain_text($tree);
        my $node_count  = $tree->descendents;
        $scotio->update_worker_status($$, 'entry', $entry->id, '0', $node_count, 0);
        # find entities, set edby and alter $tree as side effects
        my $wstat   = { type => 'entry', id => $entry->id, tnc => $node_count};
        $self->walk_tree($tree, $edb, $wstat);
        $flair  = $self->generate_flair_html($tree);

        $tree->delete;  # prevent a memory leak that can occur with this library
    }
    else {
        $log->error("Entry ".$entry->id." did not contain HTML!");
    }
    return $edb, $flair, $text;
}

sub get_entry_html {
    my $self    = shift;
    my $entry   = shift;
    my $body    = $entry->body;
    my $log     = $self->env->log;

    # entry body may contain images.  imgmunger handles this.
    my $munger  = Scot::Flair::Imgmunger->new(
        env     => $self->env,
        scotio  => $self->scotio,
    );
    my $html    = $self->clean_html($munger->process_body($entry->id, $body));
    $log->debug("IMGMUNGER HTML = $html");
    $self->scotio->alter_entry_body($entry, $html);
    return $html;
}

sub build_html_tree {
    my $self    = shift;
    my $html    = shift;

    $html       = $self->clean_html($html);
    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($html);
       $tree    ->elementify;

    return $tree;
}

sub clean_html {
    my $self    = shift;
    my $html    = shift;
    my $clean   = (utf8::is_utf8($html)) ? encode("UTF-8", $html) : $html;
    if ( $clean !~ /^<.*>/ ) {
        # if it doesn't start with something that looks like a tag wrap it in a div
        $clean = "<div>$clean</div>";
    }
    return $clean;
}


sub walk_tree {
    my $self    = shift;
    my $element = shift;
    my $edb     = shift;
    my $wstat   = shift;    # { type => , id => , }

    my $extractor   = $self->extractor;
    my $log         = $self->env->log;

    my $depth   = $element->depth;
    my $spaces  = $depth * 2;
    my $address = $element->address;

    $wstat->{pnc}++;
    
    $self->scotio->update_worker_status(
        $$, $wstat->{type}, $wstat->{id}, $address, $wstat->{tnc}, $wstat->{pnc}
    );

    $log->debug($address." "x$spaces." walking tree ".$element->tag); 

    if ( $element->is_empty ) {
        $log->debug($address." "x$spaces." empty element");
        return;
    }

    $element->normalize_content;            # concat adjacent text nodes
    my @content = $element->content_list;   # get children of node
    my @new     = ();

    for (my $index = 0; $index < scalar(@content); $index++ ) {

        my $child   = $content[$index];

        if ( $self->is_not_leaf_node($child) ) {

            $self->fix_weird_html($child); # splunk messes up ipaddr, this fixes

            if ( $self->is_not_user_defined_entity($child, $edb) ) {
                $log->debug($address." "x$spaces." not user defined, descending...");
                $self->walk_tree($child, $edb, $wstat);
            }
            push @new, $child;
        }
        else {
            my $clean = (utf8::is_utf8($child)) ? encode("UTF-8",$child) : $child;
            $log->debug($address." "x$spaces." parsing leaf node");
            $log->debug("child text = ".$clean);
            push @new, $extractor->parse($address, $edb, $clean);
        }
    }
    $log->debug($address." "x$spaces." replacing element with new content");
    $element->splice_content(0, scalar(@content), @new);
}

sub is_not_leaf_node {
    my $self    = shift;
    my $node    = shift;
    return ref($node);
}

sub is_not_user_defined_entity {
    my $self    = shift;
    my $node    = shift;
    my $edb     = shift;
    my $log     = $self->env->log;

    my $tag = $node->tag;
    return 1 if ($tag ne "span");

    my $class = $node->attr('class') // '';
    return 1 if ($self->not_external_defined_entity_class($class));

    my $type    = $node->attr('data-entity-type');
    my $value   = $node->attr('data-entity-value');

    return 1 if ( ! defined $type or ! defined $value );

    $self->extractor->add_entity($edb, $value, $type);
    $node->attr("class", "entity $class");
    return undef;
}

sub not_external_defined_entity_class {
    my $self    = shift;
    my $class   = shift;
    my @edec    = (qw(uderdef ghostbuster));
    return 1 if ( ! defined $class);
    return ! grep {/$class/} @edec;
}

sub extract_from_remoteflair {
    my $self    = shift;
    my $rfobj   = shift;
    my $log     = $self->env->log;
    my $scotio  = $self->scotio;

    my $edb     = {};   # extracted entities
    my $flair   = '';   # HTML with wrapped entities
    my $text    = '';   # plain text representation of entry
    my $html    = $rfobj->html;

    if (defined $html) {
        my $tree = $self->build_html_tree($html);
        my $node_count  = $tree->descendents;
        $scotio->update_worker_status($$, 'remoteflair', $rfobj->id, '0', $node_count, 0);
        # find entities, set edby and alter $tree as side effects
        my $wstat   = {type => 'remoteflair', id => $rfobj->id, tnc=>$node_count};
        $self->walk_tree($tree, $edb, $wstat); 
        $flair  = $self->generate_flair_html($tree);
        $text   = $self->generate_plain_text($tree);

        $tree->delete;  # prevent a memory leak that can occur with this library
    }
    else {
        $log->error("RemoteFlair ".$rfobj->id." did not contain HTML!");
    }
}

sub extract_from_alertgroup {
    my $self        = shift;
    my $alertgroup  = shift;
    my $log         = $self->env->log;

    $log->debug("===== Extracting Alerts =====");

    my $cursor  = $self->scotio->get_alerts($alertgroup);
    while (my $alert    = $cursor->next) {
        $self->extract_from_alert($alertgroup, $alert);
    }
}

sub extract_from_alert {
    my $self        = shift;
    my $alertgroup  = shift;
    my $alert       = shift;
    my $log         = $self->env->log;
    my $scotio      = $self->scotio;
    my $id          = $alert->id;

    $log->debug("~~~~~~~ Extracting Alert $id ~~~~~~~~");

    my $new     = {};
    my $data    = $alert->data;
    my $edb     = {};

    foreach my $column (keys %$data) {
        
        $log->debug("Looking at column $column");

        my $cell_aref   = $self->ensure_array($data->{$column});

        if ( $self->is_skippable_column($column) ) {
            $log->debug("...skippable column $column");
            $new->{$column} = $cell_aref;
            next;
        }

        if ( my $proc_aref = $self->is_special_column($column, $cell_aref, $edb) ) {
            $log->debug("...special column $column");
            $new->{$column} = $proc_aref;
            next;
        }

        my @cell_flair  = ();
        
        foreach my $item (@$cell_aref) {

            if ( defined $item and $item ne '' and $item ne " " ) {
                my $tree        = $self->build_html_tree($item);
                my $node_count  = $tree->descendents;
                my $wstat       = {type => 'alert', id => $alert->id, tnc => $node_count};

                $scotio->update_worker_status($$, 'alert', $alert->id, '0', $node_count, 0);

                $self->walk_tree($tree, $edb, $wstat);
                push @cell_flair, $self->generate_flair_html($tree);
                $tree->delete;
            }
            else {
                $log->debug("empty item detected and skipped.");
            }
        }
        $new->{$column} = \@cell_flair;
    }

    $log->trace("EDB after alert is ",{filter=>\&Dumper, value => $edb});

    $self->scotio->update_alert($alertgroup, $alert, $new, $edb);
}

sub ensure_array {
    my $self    = shift;
    my $data    = shift;
    my @values  = ();

    if ( ref($data) ne "ARRAY" ) {
        push @values, $data;
    }
    else {
        push @values, @{$data};
    }
    return wantarray ? @values : \@values;
}

sub is_skippable_column {
    my $self    = shift;
    my $name    = shift;

    if ( $name eq "columns" or
         $name eq "_raw" or 
         $name eq "search" ) {
        return 1;
    }
    return undef;
}

sub is_special_column {
    my $self    = shift;
    my $name    = shift;
    my $aref    = shift;
    my $edb     = shift;

    if ( $name =~ /message[_-]id/i ) {
        return $self->process_message_id($aref,$edb);
    }
    if ( $name =~ /^(lb){0,1}scanid$/i ) {
        return $self->process_scanid($aref,$edb);
    }
    if ( $name =~ /^attachment[_-]name/i or $name =~ /^attachments$/i ) {
        return $self->process_attachments($aref, $edb);
    }
    if ( $name =~ /^sentinel_incident_url/i ) {
        return $self->process_sentinel($aref, $edb);
    }
    if ( $self->is_sparkline($aref) ) {
        return $self->process_sparkline($aref, $edb);
    }
    return undef;
}

sub is_sparkline {
    my $self    = shift;
    my $aref    = shift;
    
    if ( $aref->[0] =~ /^##__SPARKLINE__##/ ) {
        return 1;
    }
    return undef;
}

sub process_message_id {
    my $self    = shift;
    my $aref    = shift;
    my $edb     = shift;
    my @new     = ();

    foreach my $item (@$aref) {
        if ( $item ne '' and $item ne " " ) {
            push @new, $self->genspan($item, "message_id");
            $edb->{entities}->{message_id}->{$item}++;
        }
    }
    return wantarray ? @new : \@new;
}

sub process_scanid {
    my $self    = shift;
    my $aref    = shift;
    my $edb     = shift;
    my @new     = ();

    foreach my $item (@$aref) {
        push @new, $self->genspan($item, "uuid1");
        $edb->{entities}->{uuid1}->{$item}++;
    }
    return wantarray ? @new : \@new;
}

sub process_attachments {
    my $self    = shift;
    my $aref    = shift;
    my $edb     = shift;
    my @new     = ();

    foreach my $item (@$aref) {
        push @new, $self->genspan($item, "filename");
        $edb->{entities}->{filename}->{$item}++;
    }
    return wantarray ? @new : \@new;
}

sub process_sentinel {
    my $self    = shift;
    my $aref    = shift;
    my $edb     = shift;
    my @new     = ();

    foreach my $item (@$aref) {
        my $image = HTML::Element->new(
            'img',
            'alt', 'view in Azure Sentinel',
            'src', '/images/azure-sentinel.png'
        );
        my $anchor  = HTML::Element->new(
            'a',
            'href', $item,
            'target', '_blank',
        );
        $anchor->push_content($image);
        push @new, $anchor->as_HTML;
    }
    return wantarray ? @new : \@new;
}

sub process_sparkline {
    my $self    = shift;
    my $aref    = shift;
    my $edb     = shift;
    my @new     = ();

    if (scalar(@$aref) < 2) {
        # could be sparkline as string in element 0
        my @norm = split(',', $aref->[0]);
        $aref   = \@norm;
    }

    my $head    = shift @$aref;
    my @vals    = grep {/\S+/} @$aref; # weed out nulls
    my $svg     = SVG::Sparkline->new(
        Line    => {
            values  => \@vals,
            color   => 'blue',
            height  => 12,
        }
    );
    push @new, $svg->to_string;
    return wantarray ? @new : \@new;
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
        if ( $self->has_splunk_ipv6_pattern($i, @content) ) {
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
    my $log     = $self->env->log;

    return undef if ( ! ref($c[$i]) );
    $log->trace("c[$i] = ".$c[$i]->tag);
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

sub generate_flair_html {
    my $self    = shift;
    my $tree    = shift;
    my $body    = $tree->look_down('_tag', 'body');
    my $log     = $self->env->log;

    $log->debug("generating flair html");

    if (! defined $body) {
        $log->warn("no <body> within html tree!");
        return undef;
    }

    my @content = $body->detach_content;

    if (scalar(@content) < 1) {
        $log->warn("no content detatched from body!");
        return undef;
    }

    $log->trace({filter => \&Dumper, value => \@content});

    if ( scalar(@content) == 1 and ref($content[0]) and $content[0]->tag eq "div" ) {
        $log->info("content was a single div, returning that element");
        return $content[0]->as_HTML;
    }

    $log->debug("creating holder div");

    my $div = HTML::Element->new('div');
    $div->push_content(@content);
    return $div->as_HTML;
}

sub generate_plain_text {
    my $self    = shift;
    my $tree    = shift;
    my $log     = $self->env->log;

    $log->debug("GENERATING PLAIN TEXT");
    $log->debug("tree = ".$tree->as_HTML);
    my $formater = HTML::FormatText->new();

    my $text    = $formater->format($tree);
    $log->debug("text = $text");
    return $text;
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
