package Scot::Extractor::Processor;

use strict;
use warnings;
use lib '../../../lib';
use utf8;

use List::Uniq ':all';
use HTML::TreeBuilder 5 -weak;
use HTML::FormatText;
use HTML::Element;
use HTML::Entities;
use Data::Dumper;
use Net::IDN::Encode ':all';
use Try::Tiny;
# use Mozilla::PublicSuffix qw(public_suffix);
use Domain::PublicSuffix;
use namespace::autoclean;
use Encode;

use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
);

has pdsuffix => (
    is      => 'ro',
    isa     => 'Domain::PublicSuffix',
    lazy    => 1,
    required    => 1,
    builder => '_build_public_suffix',
);

sub _build_public_suffix {
    my $self    = shift;
    my $sfile   = $self->env->mozilla_public_suffix_file;
    return Domain::PublicSuffix->new({ data_file => $sfile });
}

has splitre => (
    is      => 'ro',
    isa     => 'RegexpRef',
    required    => 1,
    builder => "_build_splitre",
);

sub _build_splitre {
    my $self    = shift;
    return qr{
        (
            [ \t\n]                    # spaces/tabs/newline
            | \W                       # or nonword chars
            | [\+\=\@\w\.\[\]\(\)\{\}-]+   # or words with embedded periods,dashes
                                       # with potential obsfucation [({})]
        )
    }xms;
}


=item C<process_html>

give it HTML.  
get an href of entities, and a new HTML with flair

=cut

sub process_html {
    my $self    = shift;
    my $html    = shift;
    my $log     = $self->env->log;
    my %entities;

    # clean up any utf8 problems hopefully
    $html = (utf8::is_utf8($html)) ? 
        Encode::encode_utf8($html) :
        $html;

    # ee2 should set its loglevel in config
    $log->debug("=== Processing HTML ===");
    $log->trace("source html: ",{filter=>\&Dumper, value => $html});

    # see perldoc HTML::TreeBuiler to understand options
    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($html);
       $tree    ->elementify;

    # recurse the HTML tree to find entities.  Stuff them in the 
    # \%entities reference that looks like:
    #  { 
    #      entities => [ { value=>$v, type=>$t},... ],
    #      flair    => $new_html_with_flair,
    #      text     => $plain_text, 
    #  }

    $self->walk_tree($tree, \%entities);


    # generate Text version of the HTML
    my $fmt = HTML::FormatText->new();
    my $txt = $fmt->format($tree);
	$entities{text}	    = $txt;
    $log->trace("plain text results: ",{filter=>\&Dumper, value=>$txt});

    # detach content from <html><body> and push into new <div>
    my $body    = $tree->look_down('_tag', 'body');
    my $div     = HTML::Element->new('div');
    $div->push_content($body->detach_content);

    $entities{flair}	= $div->as_HTML();

    # prevent memory leaks
    $tree->delete; 

    return \%entities;
}

sub walk_tree {
    my $self    = shift;
    my $element = shift;
    my $dbhref  = shift;
    my $level   = shift;
       $level  += 4;
    my $log     = $self->env->log;

    $log->trace(" "x$level . "Walking Node: ". $element->starttag);
    $log->trace(" "x$level . "Adress      : ". $element->address);

    if ( $element->is_empty ) {
        $log->trace(" "x$level . "------------- empty node --------");
        return;
    }

    $element->normalize_content;
    my @content = $element->content_list;
    my @new     = ();

    for( my $index = 0; $index < scalar(@content); $index++ ) {

        $log->trace(" "x$level . "Index $index");

        if ( ref $content[$index] ) {

            my $child   = $content[$index];
            $log->debug(" "x$level." Element ".$child->address." found, recursing");
            $self->fix_weird_html($child,$level);
            if ( $self->detect_user_defined_entity($child,$dbhref) ) {
                $log->debug("user defined node detected, not descending");
            }
            else {
                $self->walk_tree($child, $dbhref, $level);
            }
            push @new, $child;
        }
        else {
            my $text    = $content[$index];
            $log->debug(" "x$level . " Leaf Node content = ". $text);

            push @new, $self->parse(
                $text,
                $dbhref,
            );
            $log->trace(" "x$level."new html stack is ",{filter=>\&Dumper, value=>\@new});
        }
    }
    $element->splice_content(0, scalar(@content), @new);
    $log->trace(" "x$level." NEWCONTENT = ".$element->as_HTML);
    $log->trace(" "x$level." dbhref     = ",{filter=>\&Dumper, value=>$dbhref});
}

=item B<parse>

this recursive function parses the leaf node text using both 
multi-word regexes and single word regexes

Sample input:    The quick brown fox jumped over the lazy dog
MW Regex: /brown fox/
SW Regex: /quick/, /lazy/

1. PRE<The quick> MATCH<brown fox> POST<jumped over the lazy dog>
    a.  parse <The quick>
        1.  NO MW match
        2.  words = [The quick]
            a.  the    => no match push "the" onto @new
            b.  quick  => match    push span elment with "quick" onto @new
            up
    b. push @new the span element for brown fox
    c. parse <jumped over the lazy dog>
        1.  no MW match
        2.  words = [jumped over the lazy dog]
            a. jumped  => no match push @new, jumped 
            b. over  => no match push @new, over 
            c. the  => no match push @new, the 
            d. lazy  => match push @new, <span>lazy</span>  
            e. dog => no match push @new dog
            f. return @new
    d. return @new


=cut

sub parse {
    my $self    = shift;
    my $text    = shift;
    my $dbhref  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $reutil  = $env->regex;
    my $splitre = $self->splitre;

    my @new = ();   # hold the new element list
    
    $log->debug("Parsing $text.");

    return @new if ( $text =~ /^[\t\n ]$/); # short circuit useless text

    push @new, $self->do_multiword_matches($text, $dbhref);

    if ( scalar(@new) > 0 ) {
        $log->debug("Skipping single word regex search since multi word found");
    }
    else {
        push @new, $self->do_singleword_matches($text, $dbhref);
    }
    return wantarray ? @new : \@new;
}

sub do_multiword_matches {
    my $self    = shift;
    my $text    = shift;
    my $dbhref  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $reutil  = $env->regex;
    my @new     = ();

    $log->debug("looking for multi word matches");

    REGEX:
    foreach my $href (@{$reutil->multi_word_regexes}) {

        my $regex   = $href->{regex};
        my $type    = $href->{type};

        $log->trace("Looking for $type match in $text");

        if ( $text =~ m/$regex/ ) {

            $log->debug(" $type matches!!");

            my $pre     = substr($text, 0, $-[0]);
            my $match   = substr($text, $-[0], $+[0] - $-[0]);
            my $post    = substr($text, $+[0]);
                
            my $span;
            if ( $type eq "cidr" ) {
                $log->debug("LOOKING 4 Weird CIDR");
                $span   = $self->cidr_action($match, $dbhref);
                if ( ! defined $span ) {
                    $log->warn("problem with cidr match!");
                    next REGEX;
                }
            }
            else {
                $span = $self->span($match, $type);
                # add found match to the entity list
                push @{$dbhref->{entities}}, {
                    type    => $type,
                    value   => lc($match),
                };
            }

            push @new, $self->parse($pre, $dbhref); #look for matches in pre
            push @new, $span;
            push @new, $self->parse($post, $dbhref); #look in post

            last REGEX;
        }
    }
    return wantarray ? @new : \@new;
}

sub do_singleword_matches {
    my $self    = shift;
    my $text    = shift;
    my $dbhref  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $reutil  = $env->regex;
    my $splitre = $self->splitre;
    my @new     = ();

    $log->debug("looking for single word matches");

    my @words = ( $text =~ m/$splitre/g );

    WORD:
    foreach my $word (@words) {
        $log->trace("examining word $word");
        my $foundmatch = 0;

        REGEX:
        foreach my $href (@{$reutil->single_word_regexes}) {

            my $regex   = $href->{regex};
            my $type    = $href->{type};
            my $order   = $href->{order};

            $log->trace("Looking for $type match (order = $order)");

            if ( $word =~ m/$regex/ ) {

                $log->trace("potential match found for $type");

                my $pre     = substr($word, 0, $-[0]);
                my $match   = substr($word, $-[0], $+[0] - $-[0]);
                my $post    = substr($word, $+[0]);

                my $span    = undef;
                if ( $type eq "domain" ) {
                    $span   = $self->domain_action($match, $dbhref);
                    # $log->debug("span is ",{filter=>\&Dumper, value=>$span});
                    if ( ! defined $span ) {
                        $log->warn("false match of domain");
                        next REGEX;
                    }
                }
                elsif ( $type eq "ipaddr" ) {
                    $span   = $self->ipaddr_action($match, $dbhref);
                    if ( ! defined $span ) {
                        $log->warn("false match of ipaddr");
                        next REGEX;
                    }
                }
                elsif ( $type eq "cidr" ) {
                    $log->debug("LOOKING 4 Weird CIDR");
                    $span   = $self->cidr_action($match, $dbhref);
                    if ( ! defined $span ) {
                        $log->warn("problem with cidr match!");
                        next REGEX;
                    }
                }
                elsif ( $type eq "email" ) {
                    $span   = $self->email_action($match, $dbhref);
                    if ( ! defined $span ) {
                        $log->warn("false match of email");
                        next REGEX;
                    }
                }
                else {
                    $span = $self->span($match, $type);
                    push @{$dbhref->{entities}},{
                        type    => $type,
                        value   => lc($match),
                    };
                }
                # getting here means a valid match, i hope
                $log->debug("match validated $type $match");
                push @new, $pre if ( $pre ne '' );
                push @new, $span;
                push @new, $post if ( $post ne '' );
                $foundmatch++;
                last REGEX;
            }
            else {
                $log->trace("did not match $type");
            }
        }
        if ($foundmatch == 0) {
            $log->trace("no matches, placing unchanged $word on stack");
            push @new, $word;
        }
    }
    return wantarray ? @new : \@new;
}

=item B<span($text,$type)>

create an HTML::Element of type span to display the found entity

=cut

sub span {
    my $self    = shift;
    my $text    = shift;
    my $type    = shift;
    my $element = HTML::Element->new(
        'span',
        'class' => "entity $type",
        'data-entity-type'  => $type,
        'data-entity-value' => lc($text),
    );
    $element->push_content($text);
    return $element;
}

=item B<ipaddr_action>

de-obsfucate ipaddress and add to entities

=cut

sub ipaddr_action {
    my $self    = shift;
    my $match   = shift;
    my $dbhref  = shift;

    $match      = $self->deobsfucate_ipdomain($match);

    push @{$dbhref->{entities}}, {
        value   => $match,
        type    => "ipaddr",
    };
    return $self->span($match,"ipaddr");

}

sub cidr_action {
    my $self    = shift;
    my $match   = shift;
    my $dbhref  = shift;
    my $log     = $self->env->log;

    $log->debug("CIDR ACTION! $match");

    $match      = $self->deobsfucate_ipdomain($match);

    push @{$dbhref->{entities}}, {
        value   => $match,
        type    => "cidr",
    };
    return $self->span($match,"cidr");
}

=item B<deobsfucate_ipdomain>

A common practice is to wrap the periods in a domain or ipaddr 
with a bracket, curyl bracket, or a parenthese to prevent helpful
programs from reaching out to that ip or domain.  This removes 
those.  SCOT does this because it has it's own protections for these
and analysts complain about the "visual noise".  Also, we don't want
10.10.10.1 and 10(.)10(.)10(.)1 being different entities.

=cut

sub deobsfucate_ipdomain {
    my $self    = shift;
    my $text    = shift;
    my $log     = $self->env->log;

    $log->debug("deobsfucating ip/cidr");

    my @parts   = split(/[\[\(\{]*\.[\]\)\}]*/, $text);
    # $log->debug("$text parts = ",{filter=>\&Dumper,value=>\@parts});
    my $deobs = join('.', @parts);
    $log->debug("deobsfucated = $deobs");
    return $deobs;
}

=item B<domain_action>

Domains are tricky entities.  Thanks to ICANN we can have nearly infinite
TLD's instead of the just gov, edu, com, and org as God intended :-)
So instead of believinge that todd.bruner.foo is a domain name because it
is three words connected by periods, we go a step further and check 
against Mozilla's public suffix file.  This will tell us that bruner.foo, 
in this example, is not a valid TLD and therefore todd.bruner.foo is unlikely
to be a domain.  

=cut

### this was the old method, bbut the module it used was not easily 
### updated, so moved to the next function

sub domain_action_mozill_public_suffix {
    my $self    = shift;
    my $match   = shift;
    my $dbhref  = shift;
    my $is_domain;
    my $log     = $self->env->log;

    $log->debug("DOMAIN ACTION on $match");

    $match      = $self->deobsfucate_ipdomain($match);

    $log->debug("domain is now $match");

    try {
        $is_domain = public_suffix($match);
    }
    catch {
        $log->error("Error checking public suffix, assuming invalid domain");
        $is_domain = undef;
    };

    if ( defined $is_domain ) {
        $log->trace("we have a valid domain");
        push @{$dbhref->{entities}}, {
            value   => lc($match),
            type    => "domain",
        };
        my $span =  $self->span($match,"domain");
        $log->trace("span generated ",{filter=>\&Dumper,value=>$span});
        return $span;
    }
    return undef;
}

# this method uses a module that is easier to update

sub domain_action {
    my $self    = shift;
    my $match   = shift;
    my $dbhref  = shift;
    my $rootdom;
    my $log     = $self->env->log;

    $log->debug("Domain Action on $match");

    $match = $self->deobsfucate_ipdomain($match);

    $log->debug("domain is $match after deobsfucation");

    return try {
        $rootdom = $self->get_rdomain($match);
        if ( defined $rootdom ) {
            $log->debug("We have valid domain with root: $rootdom");
            push @{$dbhref->{entities}}, {
                value   => lc($match),
                type    => "domain",
            };
            my $span = $self->span($match, "domain");
            $log->trace("span generated ",{filter=>\&Dumper,value=>$span});
            return $span;
        }
        else {
            $log->warn("Error getting root domain: ".$self->pdsuffix->error);
            return undef;
        }
    }
    catch {
        $log->error("Error matching root domain: $_");
        return undef;
    };
}

sub get_rdomain {
    my $self    = shift;
    my $text    = shift;
    my $log     = $self->env->log;
    my $pds     = $self->pdsuffix;

    $log->debug("trying to get root domain $text");

    my $root    = $pds->get_root_domain($text);

    if ( ! defined $root ) {
        my $error   = $pds->error();
        $log->warn("root domain error: $error");
        if ( $error eq "Domain not valid") {
            # try adding a junk hostname, due to way PDS works
            $root = $pds->get_root_domain("x.".$text);
            if ( ! defined $root ) {
                $error  = $pds->error();
                $log->error("root domain final error: $error");
                return undef;
            }
        }
    }
    return $root;
}



=item B<email_action>

Emails are a username + a domain.  Not we do not perform validation
on the domain as we do in domain action.  Why?  Well an invalid e-mail
may still be an indicator.  

=cut

sub email_action {
    my $self    = shift;
    my $match   = shift;
    my $dbhref  = shift;
    my ($user, $domain) = split(/\@/,$match);
    $domain = $self->deobsfucate_ipdomain($domain);
    my $dspan   = $self->span($domain, "domain");
    push @{$dbhref->{entities}}, {
        value   => lc($domain),
        type    => "domain",
    };

    my $email = $user . '@' . $domain;
    my $lcemail = lc($email);
    my $espan = HTML::Element->new(
        'span',
        'class' => 'entity email',
        'data-entity-type'  => 'email',
        'data-entity-value' => $lcemail,
    );
    $espan->push_content($user, '@', $dspan);
    push @{$dbhref->{entities}}, {
        value   => $lcemail,
        type    => "email",
    };
    return $espan;
}

# sometimes weird html is created (looking at you splunk)
# this step will replace the weird with something ee2 can
# work with
sub fix_weird_html {
    my $self    = shift;
    my $child   = shift;
    my $level   = shift;
    my $log     = $self->env->log;

    $log->debug(" "x$level."looking for crappy splunk ipaddresses");
    # splunk likes to the following crappy thing when displaying an IPAddr
    # <em>10</em>.<em>10</em>.<em>1</em>.<em>12</em>

    my @content = $child->content_list;
    my $count   = scalar(@content);

    $log->trace(" "x$level."Scanning $count elements");
    
    for ( my $i = 0; $i < $count - 6; $i ++ ) {
        if ( $self->has_splunk_ip_pattern($i, @content) ) {
            my $new_ipaddr  = join('.', $content[$i]->as_text, 
                                        $content[$i+2]->as_text,
                                        $content[$i+4]->as_text,
                                        $content[$i+6]->as_text);
            $child->splice_content($i, 7, $new_ipaddr);
            $log->debug("Found one! Spliced element content to: ". 
                        $child->as_HTML);
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

sub fix_splunk_ipv6 {
    my $self    = shift;
    my $child   = shift;
    my $level   = shift;
    my $log     = $self->env->log;

    $log->debug(" "x$level."looking for crappy splunk ipv6 addresses");

    my @content = $child->content_list;
    my $count   = scalar(@content);

    for (my $i = 0; $i < $count - 8; $i++) {
        if ( $self->has_splunk_ipv6_pattern($i,@content) ) {
            my $new_ipv6 = join(':', $content[$i]->as_text,
                                     $content[$i+2]->as_text,
                                     $content[$i+4]->as_text,
                                     $content[$i+6]->as_text,
                                     $content[$i+7]->as_text,
                                     $content[$i+8]->as_text);
            $child->splice_content($i, 7, $new_ipv6);
            $log->debug("Found Weird SPlunk IPv6 addr: spliced to: ".$child->as_HTML);
        }
    }
}

sub has_splunk_ipv6_pattern {
    my $self    = shift;
    my $i       = shift;
    my @c       = @_;

    if ( ref($c[$i]) ) {
        if (
            $c[$i]->tag     eq "span" and
            $c[$i+1]        eq ':' and
            $c[$i+2]->tag   eq 'span' and
            $c[$i+3]        eq ':' and
            $c[$i+4]->tag   eq 'span' and
            $c[$i+5]        eq ':' and
            $c[$i+6]->tag   eq 'span' and
            ($c[$i+7] eq '0:0:0' or $c[$i+7] =~ /([0-9a-f]{1,4}:){3}/i) and
            $c[$i+8]->tag   eq 'span' 
        ) {
            return 1;
        }
    }
    return undef;
}

=item B<detect_user_defined_entity>

a user using the web ui can highligh a string (including spaces)
and designate it as a user defined entity.  the UI will transform 
the text by wrapping the hightlighted text in a specially formatted
span ( span class="userdef" data-entity-type="newtype" data-entit-value="value")

=cut

sub detect_user_defined_entity {
    my $self    = shift;
    my $child   = shift;
    my $dbhref  = shift;
    my $log     = $self->env->log;

    my $tag     = $child->tag;
    return undef if ( $tag ne "span" );
    my $class   = $child->attr('class') // '';
    $log->debug("User defined Entity detected with class = $class");
    if ( $class eq "userdef" ) {
        my $type    = $child->attr('data-entity-type');
        my $value   = $child->attr('data-entity-value');
        $log->debug("adding entity to entity dbhref");
        push @{$dbhref->{userdef}},{
            type    => $type,
            value   => lc($value),
        };
        $child->attr('class', "entity $type");
        return 1;
    }
    return undef;
}


# Author: Todd Bruner
# copyright 2017 Sandia National Labs

1;
