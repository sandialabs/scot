package Scot::Flair3::Engine;

=pod

Engine takes a target (type/id) of either entry, remoteflair or alertgroup
and generates "flair" html, plain text, and a hash of entities found and 
submits those to the SCOT database via the Io package.

Engine is designed to be called by two different workers.  The first watches 
/queue/flair and performs flairing against "core" regexes.  At the completion
of core flair, a message is placed on /queue/udflair.  The second worker
takes that message and parses the thing->flair for user defined flair.

=cut

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;
use HTML::Element;
use HTML::TreeBuilder;
use HTML::FormatText;
use Encode;
use SVG::Sparkline;
use Scot::Flair3::Io;
use Scot::Flair3::Regex;
use Scot::Flair3::UdefRegex;
use Scot::Flair3::Extractor;

has imgmunger   => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Imgmunger',
    required    => 1,
);

has workertype => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => 'core',
);

has io  => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Io',
    required    => 1,
);

has regexes => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Regex',
    required    => 1,
    lazy        => 1,
    builder     => '_build_regexes',
);

sub _build_regexes ($self) {
    return Scot::Flair3::Regex->new();
}

has udef_regexes    => (
    is          => 'ro',
    isa         => 'Scot::Flair3::UdefRegex',
    required    => 1,
    lazy        => 1,
    builder     => '_build_udef_regexes',
);

sub _build_udef_regexes ($self) {
    return Scot::Flair3::UdefRegex->new({
        io  => $self->io,
    });
}

has extractor   => (
    is              => 'ro',
    isa             => 'Scot::Flair3::Extractor',
    required        => 1,
    lazy            => 1,
    builder         => '_build_extractor',
);

sub _build_extractor ($self) {
    my $io  = $self->io;
    my $log = $io->log;
    return Scot::Flair3::Extractor->new(log => $log);
}

sub flair ($self, $message) {
    my $io  = $self->io;
    my $log = $io->log;


    if ( $self->reload_message_received($message) ) {
        $self->reload_regexes($message);
    }

    my $object  = $io->retrieve($message);

    if ( ! defined $object ) {
        $log->error("Object NOT FOUND!");
        $log->trace({filter =>\&Dumper, value=>$message});
        return undef;
    }

    # we flair in 2 steps: 1. core and then 2. user defined 
    # after each step we update everything including the remote browses
    # this should allow the analysts to see some results faster

    if ( ref($object) eq "Scot::Model::Entry" ) {
        $self->do_flair_entry($object, "core");
        $self->do_flair_entry($object, "udef");
    }

    if ( ref($object) eq "Scot::Model::Alertgroup" ) {
        $self->do_flair_alertgroup($object, "core");
        $self->do_flair_alertgroup($object, "udef");
    }

    if ( ref($object) eq "Scot::Model::RemoteFlair" ) {
        $self->do_flair_remote_flair($object, "core");
        $self->do_flair_remote_flair($object, "udef");
    }
}

sub do_flair_entry ($self, $object, $ftype) {
    my $io      = $self->io;
    my $update  = $self->flair_entry($object,$ftype);
    $io->update_entry($update);
}

sub do_flair_alertgroup ($self, $object, $ftype) {
    my $io      = $self->io;
    my $updates = $self->flair_alertgroup($object, $ftype);
    foreach my $alert_update(@{$updates->{alertupdates}} ) {
        $io->update_alert($alert_update);
    }
    $io->update_alertgroup($object, $updates->{agupdate});
}

sub do_flair_remote_flair ($self, $object, $ftype) {
    my $io      = $self->io;
    my $update  = $self->flair_remote_flair($object, $ftype);
    $io->update_remote_flair($update);
}

sub udef_flair_remote_flair ($self, $object) {
    my $io      = $self->io;
    my $update  = $self->udflair_remote_flair($object, "udef");
    $io->update_remote_flair($update);
}

sub reload_message_received ($self, $message) {
    return defined $message->{data}->{options}->{reload};
}

sub reload_regexes ($self, $message) {
    my $type    = $message->{data}->{options}->{reload};
    if ( $type eq "core" ) {
        $self->regexes->reload;
    }
    else {
        $self->udef_regexes->reload;
    }
}

sub flair_entry ($self, $entry, $ftype) {
    my $io  = $self->io;
    my $log = $io->log;
    $log->trace("--- Begin $ftype Flair Entry ".$entry->id." ---");

    my $html                 = $self->get_entry_html($entry, $ftype);
    my ($edb, $flair, $text) = $self->extract_from_html($html, $ftype);
    
    my $update = {
        entry   => $entry,
        edb     => $edb,
        flair   => $flair,
        text    => $text,
    };
    $log->trace("--- End $ftype  Flair Entry ".$entry->id." ---");
    $log->trace({filter => \&Dumper, value => $update});
    return $update
}

sub get_entry_html ($self, $entry, $ftype) {
    if ( $ftype eq "core" ) {
        my $body        = $entry->body;
        my $munger      = $self->imgmunger;
        my $munged_html = $munger->process_body($entry->id, $body);
        my $html        = $self->clean_html($munged_html);
        $self->io->alter_entry_body($entry, $html);
        return $html;
    }
    # has passed through core, no need to imagemunge and instead of body
    # we need to send the already core flaired
    my $body    = $entry->body_flair;
    return $body;
}

sub flair_remote_flair ($self, $remoteflair, $ftype) {
    my $io  = $self->io;
    my $log = $io->log;
    $log->trace("--- Begin Flair RemoteFlair ".$remoteflair->id." ---");

    my $html    = $self->get_remoteflair_html($remoteflair);
    my $clean   = $self->clean_html($html);

    my ($edb, $flair, $text) = $self->extract_from_html($clean, $ftype);

    $log->trace("--- End   Flair RemoteFlair ".$remoteflair->id." ---");
    return {
        remoteflair => $remoteflair,
        edb         => $edb,
        flair       => $flair,
        text        => $text,
    };
}

sub flair_alertgroup ($self, $alertgroup, $ftype) {
    my $io  = $self->io;
    my $log = $io->log;
    $log->trace("--- Begin $ftype Flair Alertgroup ".$alertgroup->id." ---");

    my $edb = {};
    my @alertupdates    = ();

    foreach my $alert ($io->get_alerts($alertgroup)) {
        my $alert_update = $self->flair_alert($alert, $ftype);
        my $alert_edb    = $alert_update->{edb};
        push @alertupdates, $alert_update;
        $self->merge_edb($edb, $alert_edb);
    }
    
    my $update = {
        alertupdates    => \@alertupdates,
        agupdate        => $edb,
    };

    $log->trace("--- End   Flair Alertgroup ".$alertgroup->id." ---");
    $log->trace({filter=>\&Dumper, value => $edb});
    return $update;
}


sub flair_alert ($self, $alert, $ftype) {
    my $io  = $self->io;
    my $log = $io->log;

    $log->trace("--- Begin $ftype Flair Alert".$alert->id.
                " [".$alert->alertgroup."] ---");

    my $data        = $alert->data;
    if ( $ftype ne "core" ) {
        # udef worker starts on core flaired data
        $data       = $alert->data_with_flair;
    }
    my $flairdata   = {};
    my $textdata    = {};
    my $alert_edb   = {};
    
    foreach my $column (keys %$data) {
        next if $self->skippable_column($column);

        if ( $self->contains_sparkline($data->{$column}) ) {
            my $sparkline_svg = $self->process_sparkline($data->{$column});
            $flairdata->{$column} = $sparkline_svg;
        }
        else {
            my $coltype     = $self->get_column_type($column);
            my $cellupdate  = $self->flair_cell($alert, 
                                                $coltype,
                                                $column, 
                                                $data->{$column},
                                                $ftype);

            $flairdata->{$column} = $cellupdate->{flair};
            $textdata->{$column}  = $cellupdate->{text};
            $self->merge_edb($alert_edb, $cellupdate->{edb});
        }
    }

    my $alert_update = {
        alert   => $alert,
        flair   => $flairdata,
        text    => $textdata,
        edb     => $alert_edb,
    };

    $log->trace("--- End $ftype Flair Alert".$alert->id.
                " [".$alert->alertgroup."] ---");
    $log->trace({filter=>\&Dumper, value=>$alert_update->{edb}});
    return $alert_update;
}

sub flair_cell ($self, $alert, $type, $column, $cell, $ftype) {
    my $io  = $self->io;
    my $log = $io->log;
    $log->trace("--- Begin $ftype Flair Cell $column ".$alert->id.
                " [".$alert->alertgroup."] ---");

    my @items       = $self->ensure_array($cell);
    my @flairitems  = ();
    my @textitems   = ();
    my $cell_edb    = {};

    foreach my $item (@items) {
        next if $self->item_is_empty($item);

        $log->trace("cell item: ",{filter=>\&Dumper, value=>$item});

        if ( $type eq 'normal' ) {
            my $clean   = $self->clean_html($item);
            my ($edb, $flair, $text) = $self->extract_from_html($clean, $ftype);
            $log->trace("edb : ",{filter=>\&Dumper, value=>$edb});
            push @flairitems, $flair;
            push @textitems, $text;
            $self->merge_edb($cell_edb, $edb);
        }
        else {
            my $specup = $self->flair_special_column($alert, 
                                                     $type, 
                                                     $column, 
                                                     $item);
            push @flairitems, $specup->{flair};
            push @textitems, $specup->{text};
            $self->merge_edb($cell_edb, $specup->{edb});
        }
    }

    # return \@flairitems, \@textitems, $cell_edb;
    my $updates = {
        flair   => \@flairitems,
        text    => \@textitems,
        edb     => $cell_edb,
    };
    $log->trace("--- End   Flair Cell $column ".$alert->id." [".$alert->alertgroup."] ---", );
    $log->trace({filter=>\&Dumper, value=>$updates});
    return $updates;
}

sub skippable_column ($self, $column) {
    return 1 if $column eq 'columns';
    return 1 if $column eq '_raw';
    return 1 if $column eq 'search';
    return undef;
}

sub item_is_empty ($self, $item) {
    return 1 if ! defined $item;
    return 1 if $item eq '';
    return 1 if $item eq ' ';
    return undef;
}

sub get_column_type ($self, $column) {
    return 'message_id'  if $column =~ /message[_-]id/i;
    return 'uuid1'       if $column =~ /^(lb){0,1}scanid$/i;
    return 'filename'    if $column =~ /^attachment[_-]name/i;
    return 'filename'    if $column =~ /^attachments$/i;
    return 'sentinel'    if $column =~ /^sentinel_incident_url$/i;
    return 'normal';
}

sub contains_sparkline ($self, $data) {
    if (ref($data) eq "ARRAY") {
        return 1 if $data->[0] =~ /^##__SPARKLINE__##/;
    }
    return 1 if $data =~ /^##__SPARKLINE__##/;
    return undef;
}

sub merge_edb ($self, $existing, $new) {
    # $existing is ref, so we are updating the hash as a side effect
    # edb structure:
    # { entities => { 
    #       type => {
    #            "value" => count }}
    #   cache    => {}
    # }
    $self->io->log->trace("existing => ",{filter => \&Dumper, value=>$existing});
    $self->io->log->trace("new      => ",{filter => \&Dumper, value=>$new});
    foreach my $type (keys %{$new->{entities}}) {
        foreach my $value (keys %{$new->{entities}->{$type}}) {
            my $count = $new->{entities}->{$type}->{$value};
            $existing->{entities}->{$type}->{$value} += $count;
        }
    }
}

sub extract_from_html ($self, $htmltext, $ftype) {
    my $io  = $self->io;
    my $log = $io->log;

    my $regexes = ($ftype eq "core") ?
        $self->regexes->regex_set :
        $self->udef_regexes->regex_set;

    my $tree    = $self->build_html_tree($htmltext);
    my $text    = $self->generate_plain_text($tree);
    my $edb     = {};

    $self->walk_tree($tree, $edb, $regexes, 1);

    my $flair   = $self->generate_flair_html($tree);
    $tree->delete; # prevent mem leak that can occur to ref count gc failure
    
    return $edb, $flair, $text;
}

sub walk_tree ($self, $element, $edb, $regexes, $level) {
    my $log         = $self->io->log;
    my $extractor   = $self->extractor;
    return if ( $element->is_empty );

    $log->trace("-"x$level."content is not empty");

    $element->normalize_content;
    my @content = $element->content_list;
    my @new     = (); # hold updated content

    $log->trace("-"x$level."contentlist has ".scalar(@content)." elements");

    for (my $index = 0; $index < scalar(@content); $index++) {
        my $child   = $content[$index];


        if ( $self->is_not_leaf_node($child) ) {
            $log->trace("-"x$level."Looking at child: ".$child->as_HTML);
            $self->fix_weird_html($child);
            if ( $self->is_not_predefined_entity($child, $edb) ) {
                $self->walk_tree($child, $edb, $regexes, $level++);
            }
            push @new, $child;
        }
        else {
            $log->trace("-"x$level."is leaf node: $child");
            push @new, $extractor->extract($child, $edb, $regexes, $log);
        }
    }
    $element->splice_content(0, scalar(@content), @new);
}

sub is_not_predefined_entity ($self, $child, $edb) {
    
    # couple of things to check here:
    # Flair is a 2 pass operation, 1st core, then user defined
    # so if we detect a <span class="entity... we probably 
    # have already flaired it and added it to entities, so let's 
    # skip it.
    # but other services might "pre-identify" flairable tags for 
    # us, so we should capture those and convert them to real
    # "entities"

    my $tag = $child->tag;
    return 1 if $tag ne "span"; # only in span objects
    return 1 if $self->is_not_special_class($child);
    # child is a special class 
    # nothing to do yet, but when we define it put it here
    return 0;
}

sub is_not_special_class ($self, $child) {
    my $class   = $child->attr('class');
    return 1 if ! defined $class;
    return 1 if $class eq '' or $class eq ' ';
    return 0 if $class eq 'userdef';
    return 0 if $class eq 'ghostbuster';
    return 0 if $class =~ /^entity /;
    return 1;
}

sub is_not_leaf_node ($self, $child) {
    return ref($child);
}

sub build_html_tree ($self, $htmltext) {
    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($htmltext);
       $tree    ->elementify;
    return $tree;
}

sub generate_flair_html ($self, $tree) {

    my $body    = $tree->look_down('_tag', 'body');
    return undef if ! defined $body;

    my @content = $body->detach_content;
    return undef if scalar(@content) < 1;

    if ( $self->content_is_single_div(\@content) ) {
        return $content[0]->as_HTML('<>');
    }

    my $div = HTML::Element->new('div');
    $div->push_content(@content);
    return $div->as_HTML('');
}

sub generate_plain_text ($self, $tree) {
    my $formatter   = HTML::FormatText->new();
    my $text        = $formatter->format($tree);
    return $text;
}

sub content_is_single_div ($self, $content) {
    return (
        scalar(@$content) == 1 and
        ref($content->[0]) and
        $content->[0]->tag eq "div"
    );
}

sub ensure_array ($self, $data) {
    my @values  = ();
    if ( ref($data) ne "ARRAY" ) {
        push @values, $data;
    }
    else {
        push @values, @{$data};
    }
    return wantarray ? @values : \@values;
}

sub flair_special_column ($self, $alert, $type, $column, $data) {

    my ($cell_flair,
        $cell_text,
        $cell_edb)  = $self->flair_special($data, $type);

    return {
        flair => $cell_flair, 
        text  => $cell_text, 
        edb   => $cell_edb};
}

sub process_sparkline ($self, $data) {
    my @normdata = $self->normalize_sparkline_data($data);
    my $header   = shift @normdata;
    my @values   = grep {/\S+/} @normdata;
    my $svg      = SVG::Sparkline->new(
        Line    => {
            values  => \@values,
            color   => 'blue',
            height  => 12,
        }
    );
    return $svg->to_string;
}

sub normalize_sparkline_data ($self, $data) {
    my @normalized  = ();
    if ( ref $data eq "ARRAY" ) {
        if (scalar(@$data) < 2) {
            @normalized = split(',', $data->[0]);
        }
        else {
            push @normalized, @$data;
        }
    }
    else {
        @normalized = split(',', $data);
    }
    return @normalized;
}
        

sub flair_special ($self, $data, $type) {
    my $edb     = {};
    my $flair;
    if ( $type eq 'sentinel') {
        $flair  = $self->flair_special_sentinel($data);
    }
    else {
        $flair   = $self->genspan($data, $type);
    }
    my $text    = $data;
    $edb->{entities}->{$type}->{$data}++;
    return $flair, $text, $edb;
}

sub genspan ($self, $data, $type) {
    return qq|<span class="entity $type" |.
           qq| data-entity-value="$data" |.
           qq| data-entity-type="$type">$data</span>|;
}


sub flair_special_sentinel ($self, $data) {
    my $image   = HTML::Element->new(
        'img',
        'alt', 'view in Azure Sentinel',
        'src', '/images/azure-sentinel.png',
    );
    my $anchor  = HTML::Element->new(
        'a',
        'href', $data,
        'target', '_blank',
    );
    $anchor->push_content($image);
    return $anchor->as_HTML('');
}

sub clean_html ($self, $text) {
    my $clean = utf8::is_utf8($text) ? encode("UTF-8", $text) : $text;
    if ($clean !~ /^<.*>/) {
        $clean = "<div>$clean</div>";
    }
    return $clean;
}

sub fix_weird_html ($self, $child) {
    # note: I think splunk has stopped doing the weird mangling of html
    # around ip and ipv6 addresses.  Leaving this, until I know for sure
    my @content    = $child->content_list;
    return if $self->fix_splunk_ipv4($child, @content);
    return if $self->fix_splunk_ipv6($child, @content);
}

sub fix_splunk_ipv4 ($self, $child, @content) {
    my $found   = 0;
    for (my $i = 0; $i < scalar(@content) - 6; $i++) {
        if ( $self->has_splunk_ipv4_pattern($i, @content) ) {
            my $new = join('.',
                $content[$i  ]->as_text,
                $content[$i+2]->as_text,
                $content[$i+4]->as_text,
                $content[$i+6]->as_text);
            $child->splice_content($i,7, $new);
            $found++;
        }
    }
    return $found;
}

sub has_splunk_ipv4_pattern ($self, $i, @c) {
    return undef if ! ref($c[$i]);
    return undef if $c[$i  ]->tag ne 'em';
    return undef if $c[$i+1]->tag ne '.';
    return undef if $c[$i+2]->tag ne 'em';
    return undef if $c[$i+3]->tag ne '.';
    return undef if $c[$i+4]->tag ne 'em';
    return undef if $c[$i+5]->tag ne '.';
    return undef if $c[$i+6]->tag ne 'em';
    return 1;
}

sub fix_splunk_ipv6 ($self, $child, @content) {
    # note: I think there is a bug here
    # but I also don't thing that splunk is mangling
    # the addresses like they did before
    # the potential bug is that I 
    # i'm not rebuilding the $new correctly
    # but I don't have data to try it against
    my $found   = 0;
    for (my $i = 0; $i < scalar(@content) - 6; $i++) {
        if ( $self->has_splunk_ipv6_pattern($i, @content) ) {
            my $new = join(':',
                $content[$i  ]->as_text,
                $content[$i+2]->as_text,
                $content[$i+4]->as_text,
                $content[$i+6]->as_text,
                $content[$i+8]->as_text,);
            $child->splice_content($i,7, $new);
            $found++;
        }
    }
    return $found;
}

sub has_splunk_ipv6_pattern ($self, $i, @c) {
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

__PACKAGE__->meta->make_immutable;    
1;
