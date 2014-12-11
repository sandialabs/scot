package Scot::Util::EntityExtractor;

use v5.10;
use strict;
use warnings;
# use re 'debug';

use Readonly;
use List::Uniq ':all';
use HTML::TreeBuilder 5 -weak;
use Domain::PublicSuffix;
use Data::Dumper;

use Moose;
use namespace::autoclean;

        # 
my @ss = (); # global necessitated by the nature of processing regexes
        # see Mastering Regular Expressions, 3rd Edition Chpt 7.

has 'log'       => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

has 'regexmap'  => (
    is          => 'rw',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    required    => 1,
    builder     => '_build_proclist',
    handles     => {
        get_types   => 'keys',
        get_regex   => 'get',
    },
);

has 'regexorder'    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    builder     => '_build_proc_order',
);

has     'suffix'   => (
    is          => 'ro',
    isa         => 'Domain::PublicSuffix',
    required    => 1,
    lazy        => 1,
    builder     => '_build_suffix',
);

has 'suffixfile'    => (
    is          => 'ro',
    isa         => 'Str',
    required    => '1',
);

sub _build_suffix {
    my $self    = shift;
    return        Domain::PublicSuffix->new({ data_file => $self->suffixfile});
}

Readonly my $DOMAIN_REGEX => qr{
    \b
#    (?<!\w*\.\w*[@=])
    (?=.{4,255})
    (
        (?:[a-zA-Z0-9-]{1,63}(?<!-)\.)+
        [a-zA-Z]{2,63}(?![=@])
    )\b
}xms;

Readonly my $DOMAIN_REGEX_2 => qr{
    \b
    (?<!@)
    (?!.*(?:\(|exe|docx|rar|pdf|txt|doc|ppt|pptx|pl|py|html|htm|php|jar|zip))
    (
        (?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+
        (?:com|org|net|edu|gov|[a-zA-Z]{2,6})
    )
    \b
}xms;

Readonly my $STRICT_URL_REGEX    => qr{
    (
        ((https?|ftp):\/\/)?
        (
            [a-zA-Z0-9\-_\.]+\.
            ([A-Z]{2}|com|org|new|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)
        )
        (\/[a-zA-Z0-9\-\_=\?&\.\/]*)
    )
}xms;

Readonly my $SNUMBER_REGEX => qr{
    \b(
        [sS][0-9]{6}
    )\b
}xms;

Readonly my $FILE_REGEX => qr{
	(
        [a-zA-Z0-9\^\&\'\@\{\}\[\]\,\$\=\!\-\#\(\)\%\.\+\~\_]+\.
        (exe|pdf|txt|scr|doc|docx|ppt|pptx|pl|py|html|htm|
         php|jsp|jar|rar|zip|png|jpg|odt|msg|pages|tex|wpd|
         wps|csv|dat|pps|tar|tgz|xml|vcf|aif|m4a|m3u|mp3|wav|
         wma|aif|avi|flv|m4v|mov|swf|bmp|gif|psd|eps|ps|svg|sql|
         db|kml|xhtml|ttf|otf|ico|ini|7z|deb|gz|pkg|rpm|dmg|bin|
         iso|cpp|h|sh|py|pl|bak|tmp|torrent|msi|ics|rb)
    )
}xms;

Readonly my $EMAIL_REGEX    => qr{
    (
        [a-z0-9!#$%&'*+\/?^_`{|}~-]+             # one or more of these
        (?:\.[a-z0-9!#$%&'*+\/?^_`{|}~-]+)*      # zero or more of these
        @
        (?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+  # domain before tld
        (?:[A-Z]{2}|com|org|net|edu|gov|
                    mil|biz|info|mobi|name|
                    aero|asia|jobs|museum)      # tld
        \b
    )
}xms;

Readonly my $FQDN_REGEX  => qr{
        [a-zA-Z0-9\-_\.]+                  # one or more of these
        \.(com|org|net|edu|gov|
            mil|biz|info|mobi|name|
            aero|asia|jobs|museum|[A-Za-z]{2})(?![a-zA-Z])   # tld 
}xms;

Readonly my $MD5_REGEX  => qr{
        \b
        (?!.*\@\b)([0-9a-f]{32})      # thirty two "hex" chars
        \b
}xms;

Readonly my $SHA1_REGEX => qr{
        \b                  # word boundary
        ([0-9a-f]{40})      # 40 hex chars
        \b
}xms;

Readonly my $SHA256_REGEX => qr{
        \b
        ([0-9a-f]{64})      # 64 hex chars
        \b      
}xms;

Readonly my $SCOT_FILES_REGEX   => qr{
        (<a\ href=.*/files/)([a-f0-9]{24})      
        (.*</a>)                                
}xms;
        
Readonly my $IP_REGEX   => qr{
    \b(?<!\.)
    (   # first 3 ip (with optional [.] (.) \{.\} )
        (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\(*\[*\{*\.\)*\]*\}*){3}   
        # last octet
        (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
    )
    (?!\.)\b
}xms;


sub _build_proclist {
    return { 
        "ipaddr"    => $IP_REGEX,
        "email"     => $EMAIL_REGEX,
        "md5"       => $MD5_REGEX,
        "sha1"      => $SHA1_REGEX,
        "sha256"    => $SHA256_REGEX,
        "scotfile"  => $SCOT_FILES_REGEX,
        "snumber"   => $SNUMBER_REGEX,
        "files"     => $FILE_REGEX,
        "domain"    => $DOMAIN_REGEX,
    };
}

sub _build_proc_order {
    my $self    = shift;
    my @order   = qw(
        email
        ipaddr
        md5
        sha1
        sha256
        scotfile
        snumber
        files
        domain
    );
    return \@order;
}


=item C<process_html>

give it HTML.  
get an href of entities, and a new HTML with flair

=cut

sub process_html {
    my $self    = shift;
    my $html    = shift;
    my $log     = $self->log;
    my %entities;

    $log->debug("===============");
    $log->debug("Processing HTML");

    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->implicit_body_p_tag(1);
       $tree    ->parse_content($html);
       $tree    ->elementify;

    @ss     = ();

    $self->walk_tree($tree, \%entities);

   #  need to return = { entities => [ { value=>$v, type=>$t},... ],
                       #   flair    => $new_html_with_flair,
                       #   text     => $plain_text, }

    $entities{flair}	= $tree->as_HTML;
	$entities{text}	    = $tree->as_text;
    $tree->delete; # prevent memory leaks

    $log->debug("HTML:".$entities{flair});
	
	# remove duplicates from $entities->{entities}
	$self->remove_duplicate_entities(\%entities);

    return \%entities;
}

sub walk_tree {
    my $self    = shift;
    my $element = shift;
    my $db_href = shift;
    my $level   = shift;
    my $log     = $self->log;

    $level += 4;

    $log->debug(" "x$level . "Walking node: ". $element->starttag . 
                " ". $element->address);

    if ( $element->is_empty ) {
        $log->debug(" "x$level."element is empty skipping");
        return;
    }

    $element->normalize_content;
    my @content = $element->content_list;

    for ( my $index = 0; $index < scalar(@content); $index++ ) {

        if ( ref $content[$index] ) {
            $log->debug(" " x $level . 
                        "Found ".$element->starttag." ".$element->address);
            $self->find_splunk_ips($content[$index], $level);
            $self->walk_tree($content[$index], $db_href, $level);
        }
        else {
            my $text   = $content[$index];
            $log->debug(" "x$level."Leaf node text: $text");
            my @new_content = $self->get_new_content(
                $text,
                $db_href,
                $level,
            );
            if ( scalar(@new_content) ) {
                $element->splice_content($index, 1, @new_content);
            }
        }
    }
}

sub find_splunk_ips {
    my $self    = shift;
    my $element = shift;
    my $level   = shift;
    my $log     = $self->log;
    my @content = $element->content_list;
    my $count   = scalar(@content);

    for ( my $i = 0; $i < $count - 6; $i++ ) {
        if ( $self->has_splunk_ip_pattern($i, @content) ) {
            my $newtext = $content[$i]->as_text . '.' .
                          $content[$i+2]->as_text . '.' .
                          $content[$i+4]->as_text . '.' .
                          $content[$i+6]->as_text;
            $element->splice_content($i, 7, $newtext);
        }
    }
}

sub has_splunk_ip_pattern {
    my $self    = shift;
    my $i       = shift;
    my @c       = @_;

    if ( ref($c[$i]) ) {
        if ( 
            $c[$i]->tag     eq "em" and
            $c[$i+1]        eq '.'  and
            $c[$i+2]->tag   eq "em" and
            $c[$i+3]        eq '.'  and
            $c[$i+4]->tag   eq "em" and
            $c[$i+5]        eq '.'  and
            $c[$i+6]->tag   eq "em" 
        ) {
            return 1;
        }
    }
    return undef;
}

sub get_new_content {
    my $self    = shift;
    my $text    = shift;
    my $db_href = shift;
    my $level   = shift;
    my @content = ();
    my $log     = $self->log;


    # first get all the entity matches 
    # [{value => v, type => t}]
    my @entities    = $self->get_entities($text,$level);
    push @{$db_href->{entities}}, @entities;
    $log->debug(" "x$level."Found the following Entities: ".Dumper(@entities));

                            # ( [x,y], [a,b], ...)
    my @indicies             = $self->get_match_indicies($text,$level); 
    my @sorted_indicies      = sort { $a->[0] <=> $b->[0] } @indicies;
    my $remaining_indicies  = scalar(@sorted_indicies);
    my $last                = 0; 

    # now sorted indices contains a list of the indices where matches happened

    foreach my $index_aref (@sorted_indicies) {
        
        my $start   = $index_aref->[0];
        my $end     = $index_aref->[1];
        my $length  = $end - $start;

        $log->debug(" "x$level."$remaining_indicies remain to be processed");
        $log->debug(" "x$level."start = $start end = $end length = $length");

        $remaining_indicies--;
        my $pre_match   = substr $text, $last, ($start - $last);
        my $match       = substr $text, $start, $length;
        my $post_match  = substr $text, $end;

        $log->debug(" "x$level."pre  : $pre_match");
        $log->debug(" "x$level."Match: $match");
        $log->debug(" "x$level."post : $post_match");

        my $type    = $self->get_entity_type($match, @entities); 

        if ( $type ) {
            $log->debug(" "x$level."Type: $type");

            push @content, $pre_match;
            if ( $type eq 'domain' ) {
                push @content, $self->do_domains($db_href, $match);
            }
            elsif ( $type eq 'email' ) {
                push @content, $self->do_emails($db_href, $match);
            }
            else {
                push @content, $self->do_span($db_href, $type, $match);
            }
            $last   = $end;
        }
        else {
            $log->debug(" "x$level."Type was undefined, implies partial match...");
            push @content,$pre_match, $match;
        }

        if ( $remaining_indicies == 0 ) {
            $log->debug(" "x$level."That was the last...");
            $log->debug(" "x$level."appending $post_match");
            push @content, $post_match;
        }

    }
    return @content;
}

sub get_entity_type {
    my $self    = shift;
    my $entity  = shift;    # string that matched
    my @entities    = @_;   # entities found at this level of tree
    my $log     = $self->log;

    $log->debug("getting entity type");
    $log->debug({filter => \&Dumper, value => \@entities});

    foreach my $href (@entities) {
        $log->debug("iter on:",{filter=> \&Dumper, value => $href});
        if ( $href->{value} eq $entity ) {
            return $href->{type};
        }
    }
    return undef;
}

sub add_domain {
    my $self    = shift;
    my $db_href = shift;
    my $domain  = shift;
    # add this subdomain if it is not already there
    unless ( grep { /^$domain$/ } map { $_->{value} } @{$db_href->{entities}}) {
        push @{$db_href->{entities}}, { value => $domain, type => "domain" };
    }
}

sub do_domains  {
    my $self    = shift;
    my $db_href = shift;
    my $domain  = shift;
    my $log     = $self->log;

    $log->debug("Processing Domain name $domain");

    my ( $left, $right ) = split(/\./, $domain, 2);

    $log->debug("Left = $left Right = $right");

    if ( $domain =~ m/.*\.exe/ ) {
        $log->debug("oops, not a domain afterall...");
    } 
    else {

        unless ( $domain =~ m/\..*\./ ) {
            $log->debug("No more subdomains!");
            $self->add_domain($db_href, $domain);
            my $element = HTML::Element->new(
                'span',
                'class'             => 'entity domain',
                'data-entity-type'  => 'domain',
                'data-entity-value' => $domain,
            );
            $element->push_content($domain);
            return $element;
        }

        $self->add_domain($db_href, $domain);

        my $element = HTML::Element->new(
            'span',
            'class'             => 'entity domain',
            'data-entity-type'  => 'domain',
            'data-entity-value' => $domain,
        );
        $element->push_content($left.'.');
        $element->push_content($self->do_domains($db_href, $right));
        return $element;
    }
}

sub do_emails {
    my $self    = shift;
    my $db_href = shift;
    my $email   = shift;
    my $log     = $self->log;

    $log->debug("Processing Email addr $email");

    my ( $user, $domain ) = split(/\@/, $email);

    push @{$db_href->{entities}}, { value => $domain, type => "domain" };
    push @{$db_href->{entities}}, { value => $user, type => "emailuser" };

    $log->debug("User $user Domain $domain");

    my $user_element    = HTML::Element->new(
        'span',
        'class'             => 'entity emailuser',
        'data-entity-type'  => 'emailuser',
        'data-entity-value' => $user,
    );
    $user_element->push_content($user);

    my $element = HTML::Element->new(
        'span', 
        'class'             => 'entity email',
        'data-entity-type'  => 'email',
        'data-entity-value' => $email,
    );
    $element->push_content($user_element);
    $element->push_content('@');
    my $delement =   HTML::Element->new(
        'span',
        'class'             => 'entity domain',
        'data-entity-type'  => 'domain',
        'data-entity-value' => $domain,
    );
    $delement->push_content($domain);
    $element->push_content($delement);
    return $element;
}

sub do_span {
    my $self        = shift;
    my $db_href     = shift;
    my $type        = shift;
    my $text        = shift;
    my $log         = $self->log;
    
    $log->debug("Creating $type span for $text");

    my $element = HTML::Element->new(
        'span',
        'class'             => "entity $type",
        'data-entity-type'  => $type,
        'data-entity-value' => $text,
    );
    $element->push_content($text);
    return $element;
}

# my @entities    = $self->get_entities($text);   # [{value => v, type => t}]

sub get_entities {
    my $self    = shift;
    my $text    = shift;
    my $level   = shift;
    my $log     = $self->log;
    my @entities    = ();

    $log->debug(" "x$level."Getting Entities...");

    foreach my $type ( @{$self->regexorder} ) {
        my $regex   = $self->get_regex($type);
        my @matches = uniq( $text =~ m/$regex/g );
        if ( $type  eq "files" ) {
            push @entities, $self->filter_files(@matches);
        }
        elsif ( $type eq "domain") {
            push @entities, $self->second_domain_check(@matches);
        }
        else {
            push @entities, map { { value => $_, type => $type } } @matches;
        }
    }
    return @entities;
}

sub remove_duplicate_entities {
    my $self        = shift;
	my $db_href		= shift;
	my $orig_aref	= $db_href->{entities};
    my @entities    = ();

    my %seen_value;
    my %seen_type;

    foreach my $tuple (@{$orig_aref}) {
        next if ( $seen_value{$tuple->{value}} and $seen_type{$tuple->{type}});
        push @entities, $tuple;
        $seen_value{$tuple->{value}}++;
        $seen_type{$tuple->{type}}++;
    }
    $db_href->{entities} = \@entities;
}

sub second_domain_check {
    my $self    = shift;
    my @domains = @_;
    my @good    = ();
    my $log     = $self->log;

    $log->debug("Doing secondary domain check");
    
    foreach my $domain (@domains) {
        $log->debug("checking $domain");
        my $root    = $self->suffix->get_root_domain($domain);
        if ($root) {
            $log->debug("root is $root");
            push @good, { value => $domain, type => "domain" };
        }
    }
    return @good;
}



sub filter_files {
    my $self    = shift;
    my @files   = @_;
    my @filtered    = ();
    for ( my $i = 0; $i < scalar(@files); $i = $i + 2) {
        push @filtered, { value => $files[$i], type => "file"};
    }
    return @filtered;
}

# ( [x,y], [a,b], ...)
#    my @indicies             = $self->get_match_indicies($text); 
# needs a global @ss for regex

sub get_match_indicies {
    my $self    = shift;
    my $text    = shift;
    my $level   = shift;
    my $log     = $self->log;
    my $indexre = qr/(?{ push @ss, [ $-[0], $+[0] ]; })/;
    my @indicies    = ();

    $log->debug(" "x$level."Getting Match Indicies...");

    my %seen_start;
    my %seen_end;

    foreach my $type ( @{$self->regexorder} ) {
        my $regex   = $self->get_regex($type);
        @ss         = ();
        $text       =~ m/$regex$indexre(?!)/;
        foreach my $aref (@ss) {
            if ( $seen_start{$aref->[0]} or $seen_end{$aref->[1]} ) {
                $log->debug(" "x$level."duplicate indicies dropped");
            }
            else {
                $seen_start{$aref->[0]}++;
                $seen_end{$aref->[1]}++;
                push @indicies, $aref;
            }
        }
    }
    return @indicies;
}


1;
