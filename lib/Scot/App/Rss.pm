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
    my @all_dispatches = ();
    
    foreach my $feed (@feeds) {
        my @feed_dispatches = $self->build_feed_dispatches($feed);
        if (scalar(@feed_dispatches) > 0 ) {
            push @all_dispatches, @feed_dispatches;
        }
    }
    $self->insert_into_scot(@all_dispatches);
}

sub build_feed_dispatches {
    my $self    = shift;
    my $feed    = shift;
    my $log     = $self->env->log;
    my $name    = $feed->name;
    my $uri     = $feed->uri;
    my @dispatches = ();
    my $feed_href   = $feed->as_hash;
    $log->debug("Feed is ", {filter=>\&Dumper, value=>$feed_href});
    my $xml = $self->retrieve_feed($feed_href);

    if (! defined $xml) {
        $log->error("{$name:$uri} NOT RETRIEVED!");
        return @dispatches;
    }

    my @data = $self->parse_xml($feed, $xml);

    if (scalar(@data) < 1 ) {
        $log->error("{$name:$uri} FEED PARSE FAILED");
        return @dispatches;
    }

    @dispatches = $self->build_dispatches($feed, @data);

    return @dispatches;
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
    my @normalized_data = $self->normalize_xml_rss($feed, $data);
    if ( $flag ) {
        $log->debug({filter=>\&Dumper,value=>\@normalized_data});
    }
    return wantarray ? @normalized_data : \@normalized_data;
}

sub normalize_xml_rss {
    my $self    = shift;
    my $feed    = shift;
    my $data    = shift;
    return undef if (! defined $data);
    my @items   = ();
    my $channel = {
        title   => $data->{title},
        link    => $data->{link},
        description => $data->{description},
    };
    foreach my $item (@{$data->{items}}) {
        my $item    = {
            title   => $item->{title},
            link    => $item->{link},
            description => $item->{description},
            guid        => $item->{guid},
            pubDate     => $item->{pubDate},
            channel     => $channel,
            feed        => $feed,
            epoch       => $self->get_epoch($item->{pubDate}),
        };
        push @items, $item;
    }
    return wantarray ? @items : \@items;
}

sub parse_xml_rss_parser_lite {
    my $self    = shift;
    my $feed    = shift;
    my $xml     = shift;
    my $log     = $self->env->log;
    my $data;

    my $parser  = XML::RSS::Parser::Lite->new();
    $data    = $parser->parse($xml);
    return $self->normalize_xml_rss_parser_lite($feed, $data);
}

sub normalize_xml_rss_parser_lite {
    my $self    = shift;
    my $feed    = shift;
    my $data    = shift;
    return undef if (! defined $data);
    my @items   = ();
    my $channel = {
        title   => $data->get('title'),
        link    => $data->get('link'),
        description => $data->get('description'),
    };
    for (my $i = 0; $i < $data->count(); $i++ ) {
        my $it = $data->get($i);
        my $item    = {
            title   => $it->get('title'),
            link    => $it->get('link'),
            description => $it->get('description'),
            guid        => $it->get('guid'),
            pubDate     => $it->get('pubDate'),
            channel     => $channel,
            feed        => $feed,
            epoch       => $self->get_epoch($it->get('pubDate')),
        };
        push @items, $item;
    }
    return wantarray ? @items : \@items;
}

sub parse_xml_rsslite {
    my $self    = shift;
    my $feed    = shift;
    my $xml     = shift;
    my $log     = $self->env->log;
    my $data;

    parseRSS($data, $xml);
    return $self->normalize_xml_rsslite($feed, $data);
}

sub normalize_xml_rsslite {
    my $self    = shift;
    my $feed    = shift;
    my $data    = shift;
    return undef if (! defined $data);
    my @items   = ();
    my $channel = {
        title   => $data->{title},
        link    => $data->{link},
        description => $data->{description},
    };
    foreach my $item (@{$data->{item}}) {
        my $item    = {
            title   => $item->{title},
            link    => $item->{link},
            description => $item->{description},
            guid        => $item->{guid},
            pubDate     => $item->{pubDate},
            channel     => $channel,
            feed        => $feed,
            epoch       => $self->get_epoch($item->{pubDate}),
        };
        push @items, $item;
    }
    return wantarray ? @items : \@items;
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


sub build_dispatches {
    my $self    = shift;
    my $feed    = shift;
    my @data    = @_;
    my @dispatches  = ();
    my $log     = $self->env->log;

    my $name    = $feed->name;
    my $uri     = $feed->uri;
    my $limit   = $self->day_age_limit;

    # $log->debug("data = ", {filter=>\&Dumper, value=>\@data});

    ITEM:
    foreach my $item (sort { $a->{epoch} <=> $b->{epoch} } @data) {
        if ( $self->item_old($item, $limit) ) {
            $log->debug("{$name:$uri} item $item->{title} too old. $item->{pubDate} skipping");
            next ITEM;
        }
        if ( $self->item_already_in_scot($item) ) {
            $log->debug("{$name:$uri} item $item->{title} already in scot, skipping");
            next ITEM;
        }
        my $dispatch = {
            source  => [ $name ],
            owner   => 'scot-rss',
            subject => $item->{title},
            tag     => [ 'rss' ],
            tlp     => 'unset',
            source_uri  => $item->{link},
            entry   => $self->build_entry($item),
            created => $item->{epoch},
            data    => {
                guid    => $item->{guid},
            },
            feed    => $feed,
        };
        $log->debug("{$name:$uri} Creating dispatch $dispatch->{subject}");
        push @dispatches, $dispatch;
    }
    return wantarray ? @dispatches : \@dispatches;
}

sub build_entry {
    my $self    = shift;
    my $item    = shift;
    my $pubdate     = $item->{pubDate};
    my $description = $item->{description};
    my $title       = $item->{title};
    my $link        = $item->{link};
    my $html    = 
        qq|<table class="rss_item">|.
        qq|  <tr><th align="left">Title</th><td>$title<td></tr>|.
        qq|  <tr><th align="left">Published</th><td>$pubdate<td></tr>|.
        qq|  <tr><th align="left">Link</th><td><a href="$link">$link</a><td></tr>|.
        qq|  <tr><th align="left">Description</th><td>$description<td></tr>|.
        qq|</table>|;
    return $html;
}

sub item_old {
    my $self    = shift;
    my $item    = shift;
    my $limit   = shift;
    my $log     = $self->env->log;

    # $log->debug("itemold: ",{filter=>\&Dumper, value=>$item});

    my $epoch   = $item->{epoch};
    if ( ! defined $epoch ) {
        $log->error("Undefined Epoch in item!", {filter=>\&Dumper, value=>$item});
        return undef; # skip
    }
    my $item_dt = DateTime->from_epoch(epoch => $epoch);
    my $limit_dt = DateTime->now;

    # $log->debug("item_dt ".$item_dt->ymd." ".$item_dt->hms);
    # $log->debug("limit_dt ".$limit_dt->ymd." ".$limit_dt->hms);

    $limit_dt->subtract(days => $limit);
    my $cmp = DateTime->compare($item_dt, $limit_dt);
    if ( $cmp < 0 ) {
        return 1;
    }
    return undef;
}

sub item_already_in_scot {
    my $self    = shift;
    my $item    = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');
    my $query   = {
        "data.guid" => $item->{guid}
    };
    my $obj = $col->find_one($query);
    if ( defined $obj ) {
        $log->debug("Item: $item->{title} with guid $item->{guid} already in scot");
        $log->debug("Existing dispatch is ".$obj->id);
        return 1;
    }
    return undef;
}

sub insert_into_scot {
    my $self    = shift;
    my @dispatches   = @_;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Dispatch');
    my $log     = $self->env->log;

    # $log->debug("INSERT: ",{ filter=>\&Dumper, value=>\@dispatches});
    
    foreach my $dispatch (@dispatches) {
        try {
            my $feed = $dispatch->{feed};
            my $json = {
                request => {
                    json    => $dispatch
                }
            };
            my $feed_update = {
                last_attempt    => time(),
            };
            my $dobj = $col->api_create($json);
            if (defined $dobj) {
                # update feed stats
                $feed_update->{last_article} = time();
                $feed->update_inc(article_count => 1);
            }
            else {
                $log->error("FAILED to create Dispatch with ",
                            {filter=>\&Dumper, value => $dispatch});
            }
            $feed->update({'$set' => $feed_update});
        }
        catch {
            $log->error("FAILED to create Dispatch [[$_]] with ",
                        {filter=>\&Dumper, value => $dispatch});
        };
    }
}

1;
