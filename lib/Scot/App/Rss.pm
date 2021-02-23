use strict;
use warnings;

package Scot::App::Rss;

use lib '../../../lib';
use Data::Dumper;
use DateTime;
use Try::Tiny;
use Scot::Env;
use XML::RSS;
use XML::RSS::Parser::Lite;
use XML::RSSLite;
use Mojo::UserAgent;
use IO::Socket::SSL;
use Date::Parse;
use LWP::UserAgent;
use LWP::Protocol::https;
use Moose;

extends 'Scot::App';

has ua => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    required=> 1,
    builder => '_build_ua',
);

sub _build_ua {
    my $self    = shift;
    my $ua      = Mojo::UserAgent->new();
    $ua->proxy->detect;
    $ua->transactor->name("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36");
    return $ua;
}

has lwp => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    required=> 1,
    builder => '_build_lwp',
);

sub _build_lwp {
    my $self    = shift;
    my $agent   = LWP::UserAgent->new(
        env_proxy => 1,
        timeout   => 10,
    );
    $agent->ssl_opts(
        SSL_verify_mode => 1, verify_hostname => 1, SSL_ca_patch => '/etc/ssl/certs'
    );
    $agent->proxy(['http','https'], 'http://wwwproxy.sandia.gov:80');
    $agent->agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36");
    return $agent;
}

has feeds   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_feeds',
);

sub _build_feeds {
    my $self    = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Feed');
    my $cursor  = $col->find({status=>'active'});
    my @feeds   = ();
    while (my $feed = $cursor->next) {
        push @feeds, $feed;
    }
    return \@feeds;
}

has day_age_limit => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    builder     => '_build_day_age_limit',
);

sub _build_day_age_limit {
    my $self    = shift;
    my $attr    = 'day_age_limit';
    my $default = 90;
    return $self->get_config_value($attr, $default);
}

sub process_feeds {
    my $self    = shift;
    my @feeds   = @{$self->feeds};
    my $log     = $self->env->log;

    foreach my $feed (@feeds) {
        $log->debug("Processing feed ".$feed->{name});
        $self->process_feed($feed);
    }
}

sub process_feed {
    my $self    = shift;
    my $feed    = shift;
    my $feed_href   = $feed->as_hash;
    my $xmldata = $self->retrieve_feed($feed_href);
    my $name = $feed->name;
    my $uri  = $feed->uri;

    $self->env->log->debug("process_feed $name");

    if ( ! defined $xmldata ) {
        $self->env->log->error("{$name:$uri} Failed to retrieve feed");
        return;
    }

    my @articles = $self->parse_xml($feed, $xmldata);

    if ( scalar(@articles) < 1 ) {
        $self->env->log->error("{$name:$uri} No Articles were parsed from xml: $xmldata");
        return;
    }

    foreach my $article (@articles) {
        my ($dispatch, $entry) = $self->insert_article($article, $feed);
        if (defined $dispatch and defined $entry ) {
            $self->send_mq_messages($dispatch, $entry);
            $self->update_feed($feed, $dispatch);
        }
    }
}

sub retrieve_feed {
    my $self    = shift;
    my $feed    = shift; # expect href version
    my $uri     = $feed->{uri};
    my $name    = $feed->{name};
    my $log     = $self->env->log;
    my $ua      = $self->ua;

    $log->debug("{$name:$uri} Attempting to retrieve feed");

    my $res;
    try {
        $res = $ua->get($uri)->result;
    }
    catch {
        $log->error("{$name:$uri} ERROR Retrieving: $_");
    };
    if (defined $res) {
        my $body = $res->body;
        if ( $body ) {
            return $body;
        }
        # $log->error("{$name:$uri} RES = ",{filter=>\&Dumper, value=>$res});
        $log->error("{$name:$uri} ".$res->code." ".$res->headers->location);
        $feed->{uri} = $res->headers->location;
        $feed->{count}++;
        if ($feed->{count} < 3 ) {
            return $self->retrieve_feed($feed);
        }
    }
    return undef;
}

sub retrieve_feed_lwp {
    my $self    = shift;
    my $feed    = shift;
    my $uri     = $feed->{uri};
    my $name    = $feed->{name};
    my $log     = $self->env->log;
    my $ua      = $self->lwp;

    $log->debug("{$name:$uri} Attempting to retrieve feed via lwp");

    my $request = HTTP::Request->new('GET', $uri);
    my $response = $ua->request($request);

    if ( $response->is_success() ) {
        my $body = $response->content;
        return $body;
    }
    $log->error("{$name:$uri} LWP Error: ".$response->status_line);
    return undef;
}

sub parse_xml {
    my $self    = shift;
    my $feed    = shift;
    my $xml     = shift;
    my $name    = $feed->name;
    my $uri     = $feed->uri;
    my $log     = $self->env->log;
    my @data    = try {
        $log->debug("{$name:$uri} Attempting to parse xml with XML::RSS");
        my @d= $self->parse_xml_rss($feed, $xml);
        $log->debug("{$name:$uri} Got ".scalar(@d)." items");
        if (scalar(@d) > 0) {
            return @d;
        }
        die;
    }
    catch {
        $log->debug("{$name:$uri} Attempting to parse xml with XML::RSS::Parser::Lite");
        try {
            my @d= $self->parse_xml_rss_parser_lite($feed, $xml);
            if (scalar(@d) > 0) {
                return @d;
            }
            die;
        }
        catch {
            $log->debug("{$name:$uri} Attempting to parse xml with XML::RSSLite");
            try {
                my @d= $self->parse_xml_rsslite($feed, $xml);
                if (scalar(@d) > 0) {
                    return @d;
                }
                die;
            }
            catch {
                $log->error("{$name:$uri} All attempts to parse xml FAILED");
                $log->error("Problem XML = $xml");
                return ();
            };
        };
    };
    return @data;
}

sub parse_xml_rss {
    my $self    = shift;
    my $feed    = shift;
    my $xml     = shift;
    my $log     = $self->env->log;
    my $data;
    my $flag    = 0;

    my $parser  = XML::RSS->new();
    $data       = $parser->parse($xml);
    my @normalized_data = $self->normalize_articles($feed, $data, "xml_rss");
    if ( $flag ) {
        $log->debug({filter=>\&Dumper,value=>\@normalized_data});
    }
    return wantarray ? @normalized_data : \@normalized_data;
}

sub parse_xml_rss_parser_lite {
    my $self    = shift;
    my $feed    = shift;
    my $xml     = shift;
    my $log     = $self->env->log;
    my $data;

    my $parser  = XML::RSS::Parser::Lite->new();
    $data    = $parser->parse($xml);
    my @normalized_data = $self->normalize_articles($feed, $data, "rss_parser_lite");
    return wantarray ? @normalized_data : \@normalized_data;
}

sub parse_xml_rsslite {
    my $self    = shift;
    my $feed    = shift;
    my $xml     = shift;
    my $log     = $self->env->log;
    my $data;

    parseRSS($data, $xml);
    my @normalized_data = $self->normalize_articles($feed, $data, "xml_rsslite");
    return wantarray ? @normalized_data : \@normalized_data;
}

sub normalize_articles {
    my $self    = shift;
    my $feed    = shift;
    my $data    = shift;
    my $parser  = shift;
    my $log     = $self->env->log;

    $log->debug("normalize_articles");

    return undef if ( ! defined $data);

    my @articles    = ();
    my $channel     = { 
        title   => $data->{title},
        link    => $data->{link},
        description => $data->{description},
    };

    if ($parser eq "rss_parser_lite") {
        for (my $i = 0; $i < $data->count(); $i++ ) {
            my $it = $data->get($i);
            my $guid = $it->get('guid');
            if ( ! defined $guid ) {
                $guid = $it->get('title').$it->get('link');
            }
            my $article    = {
                title   => $it->get('title'),
                link    => $it->get('link'),
                description => $it->get('description'),
                guid        => $guid,
                pubDate     => $it->get('pubDate'),
                channel     => $channel,
                feed        => $feed,
                epoch       => $self->get_epoch($it->get('pubDate')),
            };
            push @articles, $article;
        }
    }
    else {
        foreach my $item (@{$data->{items}}) {
            if ( $item->{guid} eq '' ) {
                $item->{guid} = $item->{title} . $item->{link};
            }
            my $article    = {
                title   => $item->{title},
                link    => $item->{link},
                description => $item->{description},
                guid        => $item->{guid},
                pubDate     => $item->{pubDate},
                channel     => $channel,
                feed        => $feed,
                epoch       => $self->get_epoch($item->{pubDate}),
            };
            push @articles, $article;
        }
    }
    return wantarray ? @articles : \@articles;
}

sub get_epoch {
    my $self    = shift;
    my $date    = shift;
    my $log     = $self->env->log;
    my $epoch    = Date::Parse::str2time($date, 'UTC');
    if (!defined $epoch) {
        $log->logdie("Could not parse date : $date");
    }
    return $epoch;
}

sub insert_article {
    my $self    = shift;
    my $article = shift;
    my $feed    = shift;
    my $name    = $feed->name;
    my $uri     = $feed->uri;
    my $guid    = $article->{guid};
    my $log     = $self->env->log;

    $log->debug("insert_article");

    my $dispatch_data = $self->create_dispatch_href($article, $name);

    if ( $self->already_in_scot($dispatch_data) ) {
        $self->env->log->warn("{$name:$uri} Article $guid already in SCOT");
        return undef, undef;
    }

    if ($self->article_too_old($article) ) {
        $self->env->log->warn("{$name:$uri} Article $guid too old, skipping");
        return undef, undef;
    }

    my $dispatch = $self->create_dispatch($dispatch_data, $feed); 

    if (! defined $dispatch ) {
        $log->error("{$name:$uri} Failed to create dispatch with ",
            {filter => \&Dumper, value => $dispatch_data});
        return undef, undef;
    }

    my $entry = $self->create_entry($dispatch, $article);

    if (! defined $entry ) {
        $log->error("{$name:$uri} Failed to create Entry with:",
         {filter => \&Dumper, value=> $article});
        # dispatch without an entry is useless, so delete it
        $log->warn("{$name:$uri} Removing Dispatch ".$dispatch->id);
        $dispatch->remove();
        return undef, undef;
    }
    return $dispatch, $entry;
}

sub create_dispatch_href {
    my $self    = shift;
    my $article = shift;
    my $feed_name   = shift;
    $self->env->log->debug("create_dispatch_href");
    my $dispatch = {
        source  => [ $feed_name ],
        owner   => 'scot-rss',
        subject => $article->{title},
        tag     => [ 'rss' ],
        tlp     => 'unset',
        source_uri  => $article->{link},
        created => $article->{epoch},
        data    => {
            guid    => $article->{guid},
        },
    };
    return $dispatch;
}

sub build_entry {
    my $self        = shift;
    my $article     = shift;
    my $pubdate     = $article->{pubDate};
    my $description = $article->{description};
    my $title       = $article->{title};
    my $link        = $article->{link};
    $self->env->log->debug("build_entry");
    my $html    = 
        qq|<table class="rss_article">|.
        qq|  <tr><th align="left">Title</th><td>$title<td></tr>|.
        qq|  <tr><th align="left">Published</th><td>$pubdate<td></tr>|.
        qq|  <tr><th align="left">Link</th><td><a href="$link">$link</a><td></tr>|.
        qq|  <tr><th align="left">Description</th><td>$description<td></tr>|.
        qq|</table>|;
    return $html;
}

sub article_too_old {
    my $self    = shift;
    my $article = shift;
    my $limit   = $self->day_age_limit;
    my $log     = $self->env->log;

    $log->debug("Test if Article is too old: $article->{epoch}");

    my $epoch   = $article->{epoch};
    if ( ! defined $epoch ) {
        $log->error("Undefined Epoch in article!", {filter=>\&Dumper, value=>$article});
        return undef; # skip
    }
    my $article_dt = try {
        DateTime->from_epoch(epoch => $epoch);
    } catch {
        $log->error("Invalid Epoch? $epoch. $_");
    };
    my $limit_dt = DateTime->now;

    $limit_dt->subtract(days => $limit);
    my $cmp = DateTime->compare($article_dt, $limit_dt);
    if ( $cmp < 0 ) {
        return 1;
    }
    return undef;
}

sub already_in_scot {
    my $self    = shift;
    my $article = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');
    my $query   = {
        "data.guid" => $article->{guid}
    };
    my $obj = $col->find_one($query);
    if ( defined $obj ) {
        $log->debug("Item: $article->{title} with guid $article->{guid} already in scot");
        $log->debug("Existing dispatch is ".$obj->id);
        return 1;
    }
    return undef;
}

sub create_dispatch {
    my $self    = shift;
    my $data    = shift;
    my $feed    = shift;

    $self->env->log->debug("create_dispatch");

    my $json    = { request => { json => $data } };
    my $dispatch = try {
        $self->env->mongo->collection('Dispatch')->api_create($json);
    }
    catch {
        $self->env->log->error("FAILED to Create Dispatch: $_");
        return undef; # sets $dispatch to undef
    };
    return $dispatch;
}

sub create_entry {
    my $self    = shift;
    my $dispatch    = shift;
    my $article     = shift;
    my $log     = $self->env->log;

    $log->debug("Creating Entry");
    
    my $data    = {
        target  => { type => 'dispatch', id => $dispatch->id },
        groups  => $dispatch->groups,
        summary => 0,
        body    => $self->build_entry($article),
        owner   => $dispatch->owner,
    };

    my $entry = try {
        $self->env->mongo->collection('Entry')->create($data);
    }
    catch {
        $self->env->log->error("Failed to create Entry: $_");
        return undef;
    };
    # $log->debug("Entry is ",{filter=>\&Dumper, value=>$entry});
    return $entry;
}

sub send_mq_messages {
    my ($self, $dispatch, $entry) = @_;
    my $mq  = $self->env->mq;
    $mq->send("/topic/scot",{
        action  => "created",
        data    => {
            type    => "dispatch",
            id      => $dispatch->id,
            who     => "scot-rss"
        },
    });
    $mq->send("/topic/scot",{
        action  => "created",
        data    => {
            type    => "entry",
            id      => $entry->id,
            who     => 'scot-rss'
        },
    });
}

sub update_feed {
    my $self        = shift;
    my $feed        = shift;
    my $dispatch    = shift;
    my $now         = time();

    try {
        $feed->update({
            '$set'  => {
                entry_count => 1,
                last_article    => $now,
                last_attempt    => $now,
            }
        });
        $feed->update_inc(article_count => 1);
    }
    catch {
        $self->env->log->error("Error updating Feed: $_");
    };
}

1;
