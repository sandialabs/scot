package Scot::Util::EntityExtractor;

use v5.10;
use strict;
use warnings;
# use re 'debug';

use Readonly;
use List::Uniq ':all';
use HTML::TreeBuilder 5 -weak;
use HTML::FormatText;
use HTML::Element;
use Domain::PublicSuffix;
use Mozilla::PublicSuffix qw(public_suffix);
use Data::Dumper;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Layout;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Level;
use Log::Log4perl::Appender;
use Net::IDN::Encode ':all';
use Try::Tiny;

use Moose;
use namespace::autoclean;

            # 
my @ss = (); # global necessitated by the nature of processing regexes
            # see Mastering Regular Expressions, 3rd Edition Chpt 7.

has log         => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
);

has 'regexmap'  => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    required    => 1,
    builder     => '_build_regexes',
    handles     => {
        get_regexes   => 'elements',
    },
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
    default     => '/home/tbruner/dev/Extractor/etc/effective_tld_names.dat',
);

sub _build_suffix {
    my $self    = shift;
    return        Domain::PublicSuffix->new({ data_file => $self->suffixfile});
}

Readonly my $DOMAIN_REGEX_2 => qr{
    \b                                  # word boundary
    (?<!@)                              # negative lookbehind for an '@' symbol
    (?!\d+\.\d+)                        # negative look ahead for number.number
    (?=.{4,255})                        # positive look ahead to see if we 
                                        #   have 4 to 255 characters
    (
        (?:[a-zA-Z0-9-]{1,63}(?<!-)\(*\[*\{*\.\)*\]*\}*)+ # 1st -- n "words"
        [a-zA-Z0-9-]{2,63}                  # last word, can catpute punycode
        # knock out common filenames
        (?<!php|cgi|cfm|pdf|exe|doc|htm|txt|scr|jsp|jar|rar|zip)   
        (?<!htlm|docx|pptx)
        (?<!pl|py)
    )
    \b                                   # word boundary
}xms;

Readonly my $DOMAIN_REGEX => qr{
    \b
    (?<!@)(?!.*(?:\(|exe|docx|rar|pdf|txt|doc|ppt|pptx|pl|py|html|htm|php|jar|zip))
    (
        (?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+
        (?:com|org|net|edu|gov|photo|pics|me|info|org|download|pw|help|news|support|limited|[a-zA-Z]{2,6})
    )
    \b
}xims;

Readonly my $STRICT_URL_REGEX    => qr{
    (
        ((https?|ftp):\/\/)?
        (
            [a-zA-Z0-9\-_\.]+\.
            ([A-Z]{2}|com|org|new|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)
        )
        (\/[a-zA-Z0-9\-\_=\?&\.\/]*)
    )
}xims;

Readonly my $SNUMBER_REGEX => qr{
    \b(
        [sS][0-9]{6}
    )\b
}xms;

Readonly my $FILE_REGEX => qr{
	\b
    (
        [a-zA-Z0-9\^\&\'\@\{\}\[\]\,\$\=\!\-\#\(\)\%\.\+\~\_]+\.
        (exe|pdf|txt|scr|doc|docx|ppt|pptx|pl|py|html|htm|php|jsp|jar|rar|zip|cfm)
    )
    \b
}xims;

Readonly my $EMAIL_REGEX    => qr{
    (
        [a-z0-9!#$%&'*+/?^_`{|}~-]+             # one or more of these
        (?:\.[a-z0-9!#$%&'*+/?^_`{|}~-]+)*      # zero or more of these
        @
        (?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+  # domain before tld
        (?:[A-Z]{2}|com|org|net|edu|gov|
                    mil|biz|info|mobi|name|
                    aero|asia|jobs|museum)      # tld
        \b
    )
}xims;

Readonly my $EMAIL_REGEX_2    => qr{
    \b
    (
        (?:
            [a-z0-9!#$%&'*+/?^_`{|}~-]+             # one or more of these
            (?:\.[a-z0-9!#$%&'*+/?^_`{|}~-]+)*      # zero or more of these
        )
        @
        (?:
            (?!\d+\.\d+)
            (?=.{4,255})
            (?:
                (?:[a-zA-Z0-9-]{1,63}(?<!-)\.)+
                [a-zA-Z0-9-]{2,63}
            )
        )
    )
    \b
}xims;

Readonly my $FQDN_REGEX  => qr{
        [a-zA-Z0-9\-_\.]+                  # one or more of these
        \.(com|org|net|edu|gov|
            mil|biz|info|mobi|name|
            aero|asia|jobs|museum|[A-Za-z]{2})(?![a-zA-Z])   # tld 
}xims;

Readonly my $MD5_REGEX  => qr{
        \b
        (?!.*\@\b)([0-9a-fA-F]{32})      # thirty two "hex" chars
        \b
}xims;

Readonly my $SHA1_REGEX => qr{
        \b                  # word boundary
        ([0-9a-fA-F]{40})      # 40 hex chars
        \b
}xms;

Readonly my $SHA256_REGEX => qr{
        \b
        ([0-9a-fA-F]{64})      # 64 hex chars
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

Readonly my $GOOGLE_ANALYTICS_REGEX => qr{
    (__utma=\d{9}\.(\d{9})\.\d{10}\.\d{10}\.\d{10}\.\d+\;)
}xms;

Readonly my $LAT_LONG_REGEX => qr{
    \b
    ([-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?))
    \b
}xms;


sub _build_regexes {
    my $self    = shift;
    return [
        { type  => "ipaddr",    regex  => $IP_REGEX },
        { type  => "email",     regex  => $EMAIL_REGEX_2 },
        { type  => "md5",       regex  => $MD5_REGEX },
        { type  => "sha1",      regex  => $SHA1_REGEX },
        { type  => "sha256",    regex  => $SHA256_REGEX },
        { type  => "domain",    regex  => $DOMAIN_REGEX_2 },
        { type  => "file",      regex  => $FILE_REGEX },
        { type  => "ganalytics",      regex  => $GOOGLE_ANALYTICS_REGEX },
        { type  => "snumber",   regex => $SNUMBER_REGEX },
    ];
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

    my $previous_level = $log->level();
    $log->level(Log::Log4perl::Level::to_priority('WARN'));

    $log->debug("===============");
    $log->debug("Processing HTML");

    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
#       $tree    ->implicit_body_p_tag(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       # $tree    ->ignore_ignorable_whitespace(0);
       $tree    ->parse_content($html);
       $tree    ->elementify;

    @ss     = ();

#    $tree->dump;

    $self->walk_tree($tree, \%entities);

   #  need to return = { entities => [ { value=>$v, type=>$t},... ],
                       #   flair    => $new_html_with_flair,
                       #   text     => $plain_text, }

#    $tree->dump;
    my $fmt = HTML::FormatText->new();
    my $txt = $fmt->format($tree);

    $txt =~ s/^ +//;
    $txt =~ s/ +$//;
    $txt =~ s/\n$//;

	$entities{text}	    = $txt;
#    $log->debug("PLAIN:".$fmt->format($tree));

    my $body    = $tree->look_down('_tag', 'body');
    my $div     = HTML::Element->new('div');
    $div->push_content($body->detach_content);

    $entities{flair}	= $div->as_HTML();
	# $entities{text}	    = $tree->as_text;

    $tree->delete; # prevent memory leaks

    $log->level($previous_level);
    return \%entities;
}

sub walk_tree {
    my $self    = shift;
    my $element = shift;
    my $dbhref  = shift;
    my $level   = shift;
    my $log     = $self->log;

    $level  += 4;

    $log->debug(" "x$level . "Walking Node: ". $element->starttag);
    $log->debug(" "x$level . "Adress      : ". $element->address);

    if ( $element->is_empty ) {
        $log->debug(" "x$level . "------------- empty node --------");
        return;
    }

    $element->normalize_content;
    my @content = $element->content_list;
    my @new     = ();

    $self->dump_children($level, @content);

    for( my $index = 0; $index < scalar(@content); $index++ ) {

        $log->debug(" "x$level . "Index $index");

        if ( ref $content[$index] ) {

            my $child   = $content[$index];
            $log->debug(" "x$level . " Element ".
                        $child->address." found, recursing");

            # special case for splunk Ip addresses
            $self->find_splunk_ipaddrs($child, $level);

            $self->walk_tree($child, $dbhref, $level);
            push @new, $child;
        }
        else {
            my $text    = $content[$index];
            $log->debug(" "x$level . " Leaf Node content = ". $text);
            push @new, $self->process_words(
                $level,
                $dbhref,
                $element,
                $index,
                $text
            );
            $log->debug(" "x$level."^^^^ NEW is ", join(',',@new));
        }
    }
    $element->splice_content(0, scalar(@content), @new);
    $log->debug(" "x$level." NEWCONTENT = ".$element->as_HTML);
}

sub process_words {
    my $self    = shift;
    my $level   = shift;
    my $dbhref  = shift;    # the entity database we are building for this parse
    my $element = shift;
    my $index   = shift;
    my $text    = shift;
    # tack on new stuff to existing element, we'll remove the orig later
    my $offset  = $index + 0; 
    my $log     = $self->log;

    my @words   = split(/\s+/, $text);
    my @spaces  = ( $text =~ m/(\s+)/g );

    $log->debug(" "x$level."There are ".scalar(@words).
                " words and ".scalar(@spaces). " spaces");

    for (my $j = 0; $j < scalar(@spaces); $j++ ) {
        if ( $spaces[$j] =~ /\n/ ) {
            $spaces[$j] = HTML::Element->new('br');
            $log->debug(" "x$level." newline detected, replacing with <br>");
        }
        if ( $spaces[$j] =~ /\t/ ) {
            $spaces[$j] = '    ';
            $log->debug(" "x$level." tab detected, replacing with 4 spaces");
        }
    }
    $log->debug(" "x$level."\@spaces = ". 
                join(',',map { ref($_) ? $_->as_HTML : $_ } @spaces));

    my @new = ();

    WORDS:
    foreach my $word (@words) {

        $log->debug(" "x$level."Working with Word = $word.");

        my $flairflag = 0;

        REGEX:
        foreach my $re  ( $self->get_regexes ) {

            my $type    = $re->{type};
            my $regex   = $re->{regex};

            $log->debug(" "x$level."Looking for $type");
            $log->debug(" "x$level." regex ",
                        { filter => \&Dumper, value => $regex });

            if ( $word  =~ m/$regex/ ) {

                $log->debug(" "x$level."Match Found");

                # there should be no whitespace at this point
                # pre and post matches are to catch things 
                # like http://domain.com/foo
                #      ^^^^^^           ^^^^


                my $pre     = substr($word, 0, $-[0]);
                my $match   = substr($word, $-[0], $+[0] - $-[0]);
                my $post    = substr($word, $+[0]);
                
                my $processed_match = $match;


                if ( $type eq "ipaddr" ) {
                    # remove the obsfucating [.] or {.} or (.)
                    $processed_match = $self->ipaddr_processing($match);
                }

                if ( $type eq "domain" ) { 
                    $processed_match = $self->domain_processing($match);
                }

                if ( defined $processed_match ) {

                    my $flair   = $self->do_span($type, $processed_match);
                    $log->debug(" "x$level." Insert Match flair ". 
                            $flair->as_HTML);

                    push @new, $pre     if ($pre);
                    push @new, $flair;
                    push @new, $post    if ($post);

                    push @{$dbhref->{entities}}, 
                            { value => lc($processed_match), type => $type };

                    # place a space entry after this word if there 
                    # are space entries
                    my $next_space  = shift @spaces;
                    if ( $next_space ) {# insert the proper space element
                        # $log->debug(" "x$level."inserting space...");
                        push @new, $next_space;
                    }
                    else {
                        push @new, ' '; # assume a space
                    }

                    $flairflag++;
                
                    last REGEX; 
                    # only match one thing.  later 
                    # we will have to put special match cases for
                    # emails with domains, recursive domains, etc.
                }
                else {
                    # like it never happened?
                    next REGEX;
                }
            }
        }
        unless ($flairflag) {
            # if nothing is inserted, put plain text
            $log->debug(" "x$level."No flairable content detected.");
            if ( $word ) {
                # $log->debug(" "x$level."...but there is a word here");
                push @new, $word;

                my $next_space  = shift @spaces;
                if ( $next_space ) {
                    $log->debug(" "x$level."...and a blank space");
                    push @new, $next_space;
                }
                else {
                    push @new, ' ';
                }
                $log->debug(" "x$level."splicing in $word.");
            }
            else {
                my $next_space  = shift @spaces;
                if ( $next_space ) {
                    $log->debug(" "x$level."...and a blank space");
                    push @new, $next_space;
                }
                else {
                    push @new, ' '; #need something
                }
            }

        }
    }
    # remove the original content of the element stored at index 0
    # $element->splice_content(0,1);
    $log->debug(" "x$level." Done processing words in element ".
                $element->address);
    return wantarray ? @new : \@new;
}

sub ipaddr_processing {
    my $self    = shift;
    my $ipaddr  = shift;    # might contain 10[.]10{.}10(.)1
    my @parts   = split (/[\[\{\(]*\.[\]\}\)]*/, $ipaddr);

    return join('.',@parts);
}

sub domain_processing {
    my $self    = shift;
    my $domain  = shift;
    my @parts   = split (/[\[\{\(]*\.[\]\}\)]*/, $domain);
    my $log     = $self->log;

    my $reassembled = join('.', @parts);

    $log->trace("checking public_suffix for $reassembled");
    my $is_ipaddr;
    $is_ipaddr = try {
        public_suffix($reassembled);
    }
    catch {
        $log->warn("problem with public suffix.  assuming domain");
        $is_ipaddr = 1;
    };
    if ( $is_ipaddr ) {
        $log->trace('its valid');
        return $reassembled;
    }
    $log->debug("public suffix doesn't recognize");
    return undef;
}

sub do_span {
    my $self    = shift;
    my $type    = shift;
    my $text    = shift;
    my $log     = $self->log;
    my $class   = "entity $type";

    my $element = HTML::Element->new(
        'span',
        'class'     => $class,
        'data-entity-type'  => $type,
        'data-entity-value' => $text,
    );
    $element->push_content($text);
    return $element;
}

sub dump_children {
    my $self    = shift;
    my $level   = shift;
    my @content = @_;
    my $log     = $self->log;
    $log->debug(" "x$level . "Children: ");
    $level      +=4;
    foreach my $child (@content) {
        if ( ref($child) ) {
            $log->debug(" "x$level." ".$child->address . " ". $child->starttag);
        }
        else {
            $log->debug(" "x$level." Text= ".$child);
        }
    }
}

sub find_splunk_ipaddrs {
    my $self    = shift;
    my $element = shift;
    my $level   = shift;
    my $log     = $self->log;

    $log->debug(" "x$level."looking for crappy splunk ipaddresses");
    # splunk likes to the following crappy thing when displaying an IPAddr
    # <em>10</em>.<em>10</em>.<em>1</em>.<em>12</em>

    my @content = $element->content_list;
    my $count   = scalar(@content);

    $log->trace(" "x$level."Scanning $count elements");
    
    for ( my $i = 0; $i < $count - 6; $i ++ ) {
        if ( $self->has_splunk_ip_pattern($i, @content) ) {
            my $new_ipaddr  = join('.', $content[$i]->as_text, 
                                        $content[$i+2]->as_text,
                                        $content[$i+4]->as_text,
                                        $content[$i+6]->as_text);
            $element->splice_content($i, 7, $new_ipaddr);
            $log->debug("Found one! Spliced element content to: ". 
                        $element->as_HTML);
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


1;
