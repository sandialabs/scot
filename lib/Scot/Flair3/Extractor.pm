package Scot::Flair3::Extractor;

=pod

Extractor takes a String and finds all flair-able content inside, returning
an array of text and html elements.

E.g.: 
(input) The IP is 10.10.10.1 and is active 
(output) [ "The IP is", '<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="10.10.10.1">10.10.10.1</span>', 'and is active' ]

=cut

use lib '../../../lib';

use Data::Dumper;
use Try::Tiny;
use HTML::Element;
use Encode;
use Net::IPv6Addr;
use Domain::PublicSuffix;
use Moose;
use strict;
use warnings;
use feature qw(signatures say);
no warnings qw(experimental::signatures);
use utf8;


my @ss = (); # "mastering regular expressions" 3rd Ed. Chpt 7

has log => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    required=> 1,
);

has public_suffix => (
    is          => 'ro',
    isa         => 'Domain::PublicSuffix',
    required    => 1,
    lazy        => 1,
    builder     => '_build_public_suffix',
);

sub _build_public_suffix ($self) {
    return Domain::PublicSuffix->new({
        data_file   => '/opt/scot/etc/public_suffix_list.dat'
    });
}

sub extract ($self, $input, $edb, $regexes, $log) {
    #my $edb     = {
    #    entities    => {},
    #    cache       => {},
    #};

    my $clean   = $self->clean_input($input);
    my @new     = $self->parse($regexes, $edb, $clean, $log);

    return @new;
}

sub clean_input ($self, $input) {
    my $clean   = utf8::is_utf8($input) ?
                    Encode::encode_utf8($input) :
                    $input;
    return $clean;
}

sub parse ($self, $regexes, $edb, $input, $log = undef) {
    no warnings 'recursion';
    return if $input eq '';     # nothing to parse
    my @new     = ();
    my $comparisons = 0;

    REGEX:
    foreach my $re_href (@$regexes) {
        my $re  = $re_href->{regex};
        my $rt  = $re_href->{type};

        my ($pre,
            $flair,
            $post)  = $self->find_flairable($input,
                                            $re,
                                            $rt,
                                            $edb);
        $comparisons++;

        if ( ! defined $flair ) {
            next REGEX;
        }
        $log->trace("found $rt => ".$flair->as_HTML) if defined $log;

        $log->trace("pre = $pre");
        push @new, $self->parse($regexes, $edb, $pre, $log);
        $log->trace("flair = $flair");
        push @new, $flair;
        $log->trace("post = $post");
        push @new, $self->parse($regexes, $edb, $post, $log);
        
        # we have a match, so stop
        last REGEX;
    }

    if ( scalar(@new) < 1 ) {
        push @new, $input;
    }
    $log->debug("     $comparisons Comparisons performed");
    return wantarray ? @new :\@new;
}

sub find_flairable ($self, $text, $re, $rt, $edb) {
    my $PRE     = '';
    my $attempt = 0;

    MATCH:
    while ( $text =~ m/$re/g ) {
        $attempt++;

        my $pre     = substr($text, 0, $-[0]);
        my $match   = substr($text, $-[0], $+[0] - $-[0]);
        my $post    = substr($text, $+[0]);

        

        my $flairable   = $self->post_match_actions($match, $rt, $edb);

        if ( defined $flairable ) {
            return $PRE.$pre, $flairable, $post;
        }
        else {
            # false positive
            $PRE .= $pre.$match; 
            next MATCH;
        }
    }
    # failed to find a flairable
    return undef, undef, undef;
}

sub post_match_actions ($self, $match, $rt, $edb) {
    #  special cases
    return $self->cidr_action($match, $edb)       if $rt eq "cidr";
    return $self->domain_action($match, $edb)     if $rt eq "domain";
    return $self->ipaddr_action($match, $edb)     if $rt eq "ipaddr";
    return $self->ipv6_action($match, $edb)       if $rt eq "ipv6";
    return $self->email_action($match, $edb)      if $rt eq "email";
    return $self->message_id_action($match, $edb) if $rt eq "message_id";
    # default case
    my $span    = $self->create_span($match, $rt);
    $self->add_entity($edb, $match, $rt);
    return $span;
}
    
sub cidr_action ($self, $match, $edb) {
    my $cidr    = $self->deobsfucate_ipdomain($match);    
    $self->add_entity($edb, $cidr, 'cidr');
    return $self->create_span($match, 'cidr');
}

sub domain_action ($self, $match, $edb) {
    my $log     = $self->log;
    my $domain  = $self->deobsfucate_ipdomain($match);

    return undef if $self->previous_false_positive_domain($edb, $domain);

    return try {
        my $root    = $self->get_root_domain($domain);
        if ( ! defined $root ) {
            $edb->{cache}->{domain_fp}->{$domain}++;
            $log->warn("Domain $domain marked as false positive");
            return undef;
        }
        if ( $domain =~ m/.*\.zip$/ ) {
            # assume .zip is a file extension because that is more common
            $log->warn("Domain $domain assumed to be a file, not a domain");
            return undef;
        }
        $self->add_entity($edb, $domain, 'domain');
        return $self->create_span($domain, 'domain'); # this returns out of the try
    }
    catch {
        # get root domain failed utterly
        $edb->{cache}->{domain_fp}->{$domain}++;
        $log->warn("Domain $domain marked false positive due to failure: $_");
        return undef;
    };
}

sub previous_false_positive_domain ($self, $edb, $domain) {
    return defined $edb->{cache}->{domain_fp}->{$domain};
}

sub get_root_domain ($self, $domain) {
    my $pds     = $self->public_suffix;
    my $root    = $pds->get_root_domain($domain);
    my $error   = $pds->error() // '';
    if ($error eq "Domain not valid") {
        $root   = $pds->get_root_domain('x.'.$domain);
        $error  = $pds->error();
        return undef if ! defined $root;
    }
    return $root;
}

sub ipaddr_action ($self, $match, $edb) {
    my $ipaddr  = $self->deobsfucate_ipdomain($match);
    $self->add_entity($edb, $ipaddr, 'ipaddr');
    return $self->create_span($ipaddr, 'ipaddr');
}

sub ipv6_action ($self, $match, $edb) {
    my $ipobj   = try {
        Net::IPv6Addr->new($match);
    }
    catch {
        $self->log->warn("failed to validate potential ipv6: $match");
        return undef;
    };

    return undef if ! defined $ipobj;

    my $standardized = $ipobj->to_string_preferred();
    $self->add_entity($edb, $standardized, 'ipv6');
    return $self->create_span($standardized, 'ipv6');
}

sub email_action ($self, $match, $edb) {
    my ($user, $domain) = split(/\@/, $match);
    $domain = $self->deobsfucate_ipdomain($domain);
    my $dspan   = $self->create_span($domain, 'domain');
    $self->add_entity($edb, $domain, 'domain');

    my $email   = lc($user . '@' . $domain);
    my $espan   = HTML::Element->new(
        'span',
        'class'             => 'entity email',
        'data-entity-type'  => 'email',
        'data-entity-value' => $email,
    );
    $espan->push_content($user, '@', $dspan);
    $self->add_entity($edb, $email, 'email');
    return $espan;
}

sub message_id_action ($self, $match, $edb) {
    my $msg_id = $match;
    if ( $match !~ m/^<.*>$/ ) {
        $msg_id =~ s/^&lt;/</;
        $msg_id =~ s/&gt;$/>/;
    }
    $self->add_entity($edb, $msg_id, 'message_id');
    return $self->create_span($msg_id, 'message_id');
}

sub create_span ($self, $match, $rt) {
    my $element = HTML::Element->new(
        'span',
        'class'             => "entity $rt",
        'data-entity-type'  => $rt,
        'data-entity-value' => lc($match),
    );
    $element->push_content($match);
    return $element;
}

sub add_entity ($self, $edb, $match, $rt) {
    $edb->{entities}->{$rt}->{lc($match)}++;
}

sub deobsfucate_ipdomain ($self, $text) {
    my @parts   = split(/[\[\(\{]*\.[\]\)\}]*/, $text);
    my $clear   = join('.',@parts);
    return $clear;
}


__PACKAGE__->meta->make_immutable;
1;
