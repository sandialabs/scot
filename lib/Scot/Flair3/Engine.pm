package Scot::Flair3::Engine;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Scot::Flair3::Timer;
use Moose;
use feature qw(signatures say);
no warnings qw(experimental::signatures);

use Data::Dumper;
use Encode;
use HTML::Element;
use HTML::TreeBuilder;
use HTML::FormatText;
use JSON;
use SVG::Sparkline;
use Scot::Flair3::Extractor;
use Scot::Flair3::Io;
use Scot::Flair3::Imgmunger;
use Scot::Flair3::Regex;
use Scot::Flair3::Stomp;
use Time::HiRes qw(gettimeofday tv_interval);

has stomp   => ( 
    is          => 'ro',
    isa         => 'Scot::Flair3::Stomp',
    lazy        => 1,
    required    => 1,
    builder     => '_build_stomp',
);

sub _build_stomp ($self) {
    return Scot::Flair3::Stomp->new();
}

has io      => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Io',
    required    => 1,
    lazy        => 1,
    builder     => '_build_io',
);

sub _build_io ($self) {
    my $stomp   = $self->stomp;
    say "build_io";
    say Dumper($stomp);
    return Scot::Flair3::Io->new(stomp => $stomp);
}

has imgmunger   => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Imgmunger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_imgmunger',
);

sub _build_imgmunger ($self) {
    my $io = $self->io;
    return Scot::Flair3::Imgmunger->new(io => $io);
}

has extractor   => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Extractor',
    required    => 1,
    lazy        => 1,
    builder     => '_build_extractor',
);

sub _build_extractor ($self) {
    my $io  = $self->io;
    my $log = $io->log;
    return Scot::Flair3::Extractor->new(log => $log);
}

has regex  => (
    is          => 'ro',
    isa         => 'Scot::Flair3::Regex',
    required    => 1,
    builder     => '_build_core_regex',
);

sub _build_core_regex ($self) {
    my $io  = $self->io;
    return Scot::Flair3::Regex->new(io => $io);
}

has log     => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_log',
);

sub _build_log ($self) {
    my $io  = $self->io;
    return $io->log;
}

sub process_message ($self, $message) {
    my $io      = $self->io;
    my $log     = $self->log;

    $log->trace("Processing Message: ",{filter => \&Dumper, value => $message});

    if ( $message->{headers}->{destination} eq "/topic/flair" ) {
        return $self->process_topic($message);
    }

    my $object  = $io->retrieve($message);

    if ( ! defined $object ) {
        $log->error("Object not found!");
        return { error => "Object NOT Found" };
    }
    $log->trace("retrieved ".ref($object)." ".$object->id);
    my $type    = lc($message->{body}->{data}->{type});
    $log->trace("type is $type");
    my $status;
    $status = $self->process_entry($object)           if ( $type eq "entry" );
    $status = $self->process_alertgroup($object)      if ( $type eq "alertgroup" );
    $status = $self->process_remoteflair($object)     if ( $type eq "remoteflair" );
    return $status;
}

sub process_topic ($self, $message) {
    my $log = $self->log;
    if ( defined $message->{data}->{options}->{reload} ) {
        $self->regex->reload;
        $log->debug("Reloaded regular expressions");
        return 'success';
    }
}

sub process_entry ($self, $entry) {

    my $timer  = get_timer("process entry", $self->log);
    my $update = $self->flair_entry($entry);
    $self->io->update_entry($update);
    $self->log->debug("finished flair of entry ".$entry->id);
    &$timer;
    return "success";
}

sub flair_entry ($self, $entry) {
    my $io  = $self->io;
    my $log = $self->log;
    my $id  = $entry->id;

    $log->info("- Begin Flair Entry $id -");

    my $html                    = $self->get_entry_html($entry);
    my ($edb, $flair, $text)    = $self->extract_from_html($html);
    my $update  = {
        entry   => $entry,
        edb     => $edb,
        flair   => $flair,
        text    => $text,
    };

    $log->info("- End   Flair Entry $id -");
    $log->debug("update = ",{filter=>\&Dumper, value => $update});
    return $update;
}

sub get_entry_html ($self, $entry) {
    my $body        = $entry->body;
    my $munger      = $self->imgmunger;
    my $munged_html = $munger->process_body($entry->id, $body);
    my $html        = $self->clean_html($munged_html);
    $self->io->alter_entry_body($entry, $html);
    return $html;
}

sub process_alertgroup ($self, $alertgroup) {
    my $timer = get_timer('process alertgroup', $self->log);
    my $update = $self->flair_alertgroup($alertgroup);
    $self->apply_alert_updates($update);
    $self->update_alertgroup($alertgroup, $update);
    $self->log->debug("finished flair of alertgroup");
    &$timer;
}

sub flair_alertgroup ($self, $alertgroup) {
    my $io  = $self->io;
    my $log = $self->log;
    my $id  = $alertgroup->id;

    $log->info("- Begin Flair Alertgroup $id -");

    my $edb         = {};
    my @alertupdates= ();
    my @alerts      = $io->get_alerts($alertgroup);

    foreach my $alert (@alerts) {

        my $alert_update    = $self->flair_alert($alert);
        my $alert_edb       = $alert_update->{edb};
        push @alertupdates,   $alert_update;
        $self->merge_edb($edb, $alert_edb);
    }

    my $update  = {
        alertupdates    => \@alertupdates,
        agupdate        => $edb,
    };


    $log->info("- End   Flair Alertgroup $id -");
    $log->trace("alertgroup update: ",{filter=>\&Dumper, value=>$update});
    return $update;
}

sub flair_alert ($self, $alert) {
    my $io      = $self->io;
    my $log     = $self->log;
    my $id      = $alert->id;
    my $agid    = $alert->alertgroup;

    $log->info("___ Begin Flair Alert $id [$agid] ___");
    my $data    = $alert->data;
    my $flair   = {};
    my $text    = {};
    my $edb     = {};
    $log->trace("ALERT DATA is ",{filter=>\&Dumper, value=>$data});

    foreach my $column (keys %$data) {

        next if $self->skippable_column($column);

        my $celldata = $data->{$column};

        if ( $self->contains_sparkline($celldata) ) {
            my $svg = $self->process_sparkline($celldata);
            $flair->{$column} = $svg;
        }
        else {
            my $coltype       = $self->get_column_type($column);
            my $cellupdate    = $self->flair_cell($alert, $coltype, $column, $celldata);
            $flair->{$column} = $cellupdate->{flair};
            $text->{$column}  = $cellupdate->{text};
            $self->merge_edb($edb, $cellupdate->{edb});
        }
    }

    my $update  = {
        alert   => $alert,
        flair   => $flair,
        text    => $text,
        edb     => $edb,
    };

    $log->info("___ End   Flair Alert $id [$agid] ___");
    $log->trace("alert update: ",
        {filter=>\&Dumper, value=>[$update->{flair}, $update->{edb}]});
    return $update;
}

sub flair_cell ($self, $alert, $ctype, $column, $celldata) {
    my $io      = $self->io;
    my $log     = $self->log;
    my $id      = $alert->id;
    my $agid    = $alert->alertgroup;

    $log->info("_____ Begin Flair Alert $id [$agid] Cell $column $ctype _____");

    my @items = $self->ensure_array($celldata); 
    my @flair = ();
    my @text  = ();
    my $edb   = {};

    foreach my $item (@items) {

        next if $self->item_is_empty($item);

        $log->trace("item = $item");

        if ( $ctype eq "normal" ) {
            my $clean                   = $self->clean_html($item);
            my ($iedb, $iflair, $itext) = $self->extract_from_html($clean);
            push @flair, $iflair;
            push @text, $itext;
            $self->merge_edb($edb, $iedb);
        }
        else {
            my $spupdate = $self->flair_special_column($alert, $ctype, $column, $item);
            push @flair, $spupdate->{flair};
            push @text,  $spupdate->{text};
            $self->merge_edb($edb, $spupdate->{edb});
        }
    }
    my $update  = { flair => \@flair, text => \@text, edb => $edb };


    $log->info("_____ End   Flair Alert $id [$agid] Cell $column $ctype _____");
    $log->trace("cell update: ",{filter => \&Dumper, value => $update});
    return $update;
}


sub apply_alert_updates($self, $update) {
    $self->log->trace("Applying Alert Updates");
    my $timer   = get_timer("apply alert updates", $self->log);
    my @updates = @{$update->{alertupdates}};
    foreach my $alertup (@updates) {
        $self->io->update_alert($alertup);
    }
    &$timer;
}

sub update_alertgroup ($self, $alertgroup, $update) {
    my $timer   = get_timer("update alertgroup", $self->log);
    my $agedb = $update->{agupdate};
    $self->log->trace("AGEDB ===> ",{filter=>\&Dumper, value=>$agedb});
    $self->io->update_alertgroup($alertgroup, $agedb);
    &$timer;
}

sub process_remoteflair ($self, $remoteflair) {
    my $core_update = $self->flair_remoteflair($remoteflair, "core");
    $self->update_remoteflair($core_update);

    my $udef_update = $self->flair_remoteflair($remoteflair, "udef");
    $self->update_remoteflair($udef_update);
    return "success";
}

sub extract_from_html ($self, $htmltext) {
    my $io  = $self->io;
    my $log = $io->log;

    my $regexes = $self->regex->regex_set;
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
        if ( $self->is_leaf_node($child) ) {
            $log->trace("-"x$level."is leaf node: $child");
            push @new, $extractor->extract($child, $edb, $regexes, $log);
        }
        elsif ( $self->is_predefined_entity($child, $edb) ) {
            push @new, $child;
        }
        else {
            $log->trace("-"x$level."Looking at child: ".$child->as_HTML);
            $self->fix_weird_html($child);
            $self->walk_tree($child, $edb, $regexes, $level++);
            push @new, $child;
        }
    }
    $element->splice_content(0, scalar(@content), @new);
}

sub is_predefined_entity ($self, $child, $edb) {
    
    # other services might "pre-identify" flairable tags for 
    # us, so we should capture those and convert them to real
    # "entities"
    my $log = $self->log;
    $log->trace("checking for predefined entity");
    my $tag = $child->tag;
    $log->trace("tag is $tag");
    # predefined entities must be in spans
    return undef if ($tag ne "span");
    $log->trace("child is a span");

    my $class   = $child->attr('class');
    # must have class of entity
    return undef if (! defined $class);
    return undef if ($class !~ /entity/);
    $log->trace("child is an entity");

    my $type    = $child->attr('data-entity-type');
    my $value   = $child->attr('data-entity-value');
    # must have data-entity-type and data-entity-value attributes
    return undef if ( ! defined $type or ! defined $value ); 
    $log->trace("child is entity of type $type and value $value");

    # add this to the edb
    $edb->{$type}->{$value}++;
    return 1;
}

sub is_leaf_node ($self, $child) {
    return ref($child) eq '';
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

    my $update  = {};
    ($update->{flair}, 
     $update->{text}, 
     $update->{edby}) = $self->flair_special($data, $type);
    return $update;
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

sub item_is_entity ($self, $item) {
    return $item =~ /<span class="entity/;
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
        if ( defined $data->[0] ) {
            return 1 if $data->[0] =~ /^##__SPARKLINE__##/;
        }
    }
    return 1 if $data =~ /^##__SPARKLINE__##/;
    return undef;
}

sub flair_remoteflair ($self, $remoteflair) {
    my $io  = $self->io;
    my $log = $self->log;
    my $id  = $remoteflair->id;

    $log->info("_ Begin Flair RemoteFlair $id _");

    my $html                    = $self->get_remoteflair_html($remoteflair);
    my $clean                   = $self->clean_html($html);
    my ($edb, $flair, $text)    = $self->extract_from_html($clean);

    my $update  = {
        remoteflair => $remoteflair,
        edb         => $edb,
        flair       => $flair,
        text        => $text,
    };
    
    $log->info("... End   Flair RemoteFlair $id ...");
    $log->trace("Remoteflair update: ",{filter=>\&Dumper, value=>$update});
    return $update;
}

sub get_remoteflair_html ($self, $remoteflair) {
    return $remoteflair->html;
}

sub convert_rf_entities ($self, $remoteflair) {
    my $entities = $remoteflair->results->{entities};
    my $edb      = {};
    foreach my $h (@$entities) {
        $edb->{ $h->{type} }->{ $h->{value} }++;
    }
    return $edb;
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
    $self->log->trace("Merged   => ",{filter=>\&Dumper, value=>$existing});
}

__PACKAGE__->meta->make_immutable;    
1;
