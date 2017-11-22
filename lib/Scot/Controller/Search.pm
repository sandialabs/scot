package Scot::Controller::Search;


=head1 Name

Scot::Controller::Search

=head1 Description

Proxy Search requests to elasticsearch

=cut

use Data::Dumper;
use Try::Tiny;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper::HTML qw(dumper_html);
use strict;
use warnings;
use base 'Mojolicious::Controller';

=head1 Routes

=over 4

=item I<POST> B<POST /scot/api/v2/search>

=cut

sub search {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');
    my $esua    = $env->esproxy;

    $log->trace("------------");
    $log->trace("Handler is processing a POST (search) from $user");
    $log->trace("------------");

    my $request = $self->req;

    $log->debug("Search request: ",{filter=>\&Dumper, value=>$request});

    my $body    = $request->body;

    $log->debug("Search body: ",{filter => \&Dumper, value=>$body});

    my $params  = $request->params->to_hash;

    $log->debug("Search Params: ",{filter=>\&Dumper, value=>$params});

    my $response = $esua->do_request_mojo(  # ... href of json returned.
        'POST',
        '',
        {
            params  => $params,
            json    => $body,
        },
    ); 
    #my $response = $esua->do_request_esclient(  # ... href of json returned.
    #    {
    #        params  => $params,
    #        json    => $body,
    #    },
    # );

    $log->debug("Got Response: ", {filter=>\&Dumper, value=>$response});
    $self->put_stat("search initiated", 1);
    $self->do_render($response);
}

sub hitsearch {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $es      = $env->es;
    my $request = $self->req;
    my $body    = $request->body;
    my $params  = $request->params->to_hash;
    my $match   = $params->{match};
    my $query   = {
        query   => {
            match   => {
                _all    => $match
            }
        }
    };

    $log->debug("Looking for hitsearch: ",{filter=>\&Dumper, value=>$query});
    my $results = $es->search("scot", [ 'alert','entry' ], $query);
    $log->debug("hitsearch got: ",{filter=>\&Dumper, value=>$results});
    my $hits    = {
        count   => $results->{hits}->{total},
    };
    $self->put_stat("hitsearch initiated",1);
    $self->do_render($hits);
}

sub put_stat {
    my $self    = shift;
    my $metric  = shift;
    my $value   = shift;
    my $env     = $self->env;
    my $nowdt   = DateTime->from_epoch(epoch => $env->now);
    my $col     = $env->mongo->collection('Stat');
    $col->increment($nowdt, $metric, $value);
}

sub newsearch {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $self->session('user');
    my $esua    = $env->esproxy;

    $log->trace("----NEW-----");
    $log->trace("Handler is processing a POST (search) from $user");
    $log->trace("------------");

    my $request = $self->req;
    my $qstring = $request->param('qstring');
    
    if ( $qstring ne "" ) {
        $qstring = $qstring . "*";
    }

    $log->debug("Search String: $qstring");

    my $response = $esua->do_request_new(  # ... href of json returned.
        {
            query       => {
                filtered    => {
                    filter  => {
                        or  => [
                            { term  => { _type  => { value => "alert" } } },
                            { term  => { _type  => { value => "entry" } } },
                            { term  => { _type  => { value => "alertgroup" } } },
                            { term  => { _type  => { value => "event" } } },
                            { term  => { _type  => { value => "incident" } } },
                            { term  => { _type  => { value => "intel" } } },
                            { term  => { _type  => { value => "guide" } } },
                            { term  => { _type  => { value => "task" } } },
                            { term  => { _type  => { value => "signature" } } },
                            { term  => { _type  => { value => "entity" } } },
                        ]
                    },
                    query   => {
                        query_string    => {
                            query   => $qstring,
                            rewrite => "scoring_boolean", #scoring boolean can cause issues with >1024 sized query
                            #analyzer => "scot_analyzer",
                            analyze_wildcard => "true",
                        }
                    }
                }
            },
            highlight   => {
                #pre_tags    => [ qq|<div class="search_highlight">| ],
                #post_tags   => [ qq|</div>| ],
                pre_tags    => [qq||],
                post_tags   => [qq||],
                require_field_match => \0, # encode will conver to json false
                fields  => {
                    '*' => {
                        fragment_size   => 100,
                        number_of_fragments => 1,
                    },
                },
            },
            _source => [ qw(id target body_plain alertgroup data value) ],
            sort    => [ qw(_score) ],
            #min_score   => 0.8,
            size => 50,
        },
    ); 

    my $hits    = $response->{hits};
    my $total   = $hits->{total};
    my $records = $hits->{hits};

    my @results;
    foreach my $record (@$records) {
        if ( $record->{_type} eq "entry") {
            push @results, {
                id          => $record->{_source}->{target}->{id},
                type        => $record->{_source}->{target}->{type},
                entryid     => $record->{_id},
                score       => $record->{_score},
                snippet     => $record->{_source}->{body_plain},
                highlight   => $record->{highlight}->{body_plain},
            };
        }
        elsif ($record->{_type} eq "entity") {
            push @results, {
                id          => $record->{_id},
                type        => $record->{_type},
                score       => $record->{_score},
                snippet     => $record->{_source}->{_raw},
                highlight   => $record->{_source}->{value},
            };
        }
        else {
            push @results, {
                id          => $record->{_id},
                type        => $record->{_type},
                score       => $record->{_score},
                snippet     => $record->{_source}->{_raw},
                highlight   => $record->{highlight},
            };
        }
    }

    $log->debug("Got Response: ", {filter=>\&Dumper, value=>$response});
    $self->put_stat("search initiated", 1);
    $self->do_render({
        totalRecordCount    => $total,
        queryRecordCount    => scalar(@results),
        records             => \@results,
    });

}

sub do_render {
    my $self    = shift;
    my $code    = 200;
    my $href    = shift;
    $self->render(
        status  => $code,
        json    => $href,
    );
}

# given set of tags, return the things that are attached to them
# user gives:  "tag=foo,!bar,boom"

# move this? to Api for filtering based on tags

sub search_tags {
    my $self    = shift;
    my $terms   = shift; # ... comma sep, optionally prepended with !
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("Searching for tags matching ", 
                { filter =>\&Dumper, value=>$terms});

    my ($match_aref, $anti_aref) = $self->get_match_anti_match_arrays($terms);

    # look for matching tags, but check that for a anti match 

    my $col = $mongo->collection('Tag');
    my $cur = $col->find({ value => { '$in' => $match_aref } });

    my @found   = ();

    TAG:
    while ( my $tag = $cur->next ) {
        my $type    = $tag->target->{type};
        my $id      = $tag->target->{id};
        # look for other tags with this target
        if ( scalar(@$anti_aref) > 0 ) {
            my $addcur  = $col->find({
                'target.type'   => $type,
                'target.id'     => $id,
            });
            while ( my $atag = $addcur->next ) {
                my $value = $atag->value;
                if ( grep {/$value/} @$anti_aref ) {
                    # we have an anti match, move to the next
                    next TAG;
                }
            }
        }
        # made it this far, let's add it as a match
        push @found, { type => $type, id => $id };
    }
    return wantarray ? @found : \@found;
}

# coding an implementation of the previous
# scot search in case things are weird
# with elastic

sub get_match_anti_match_arrays {
    my $self    = shift;
    my $cslist  = shift; #... comma seperated list string
    my @term    = split(/,/, $cslist);
    my @match   = ();
    my @anti    = ();

    foreach my $t (@term) {
        if ( $t =~ /^\!/ ) {
            push @anti, $t;
            next;
        }
        push @match, $t;
    }
    return \@match, \@anti;
}
sub max {
    my $a   = shift;
    my $b   = shift;
    return ( $a > $b ) ? $a : $b;
}


# give it text and the match string
# will return html with highligted matchstring within snipped of text
sub create_highlighted_snippet {
    my $self        = shift;
    my $matchstr    = shift;
    my $text        = shift;

    my $side_len    = 50;
    my $position    = index(lc($text), lc($matchstr));
    my $highlight   = '';

    unless ($position >= 0) {
        return $highlight;
    }

    $highlight = substr(
        $text,
        max($position - $side_len, 0),
        ($side_len * 2 + length($matchstr))
    );
    my $quoted_match    = quotemeta($matchstr);

    $highlight  = encode_entities($highlight);
    $highlight  =~ s/($quoted_match)/<span class="snip_hightlight">$1<\/span>/gi;
    return $highlight;
}

sub ngram_search {
    my $self    = shift;
    my $query   = lc($self->param('query'));
    my $ngutil  = $self->ngutil;
    my %results = ();
    my $env     = $self->env;
    my $total_search_timer = $env->get_timer("total search time");

    my @qngrams = $ngutil->get_query_ngrams($query);

    my $mongo_time  = $env->get_timer("mongo query time");
    my $col = $self->env->mongo->collection('Ngram');
    my $cur = $col->find({ngram => {'$in' => \@qngrams} });
    &$mongo_time;


    my %seen;
    my %max;
    my $build_sets_time = $env->get_timer("build sets");
    while ( my $ngo = $cur->next ) {
        my $target_aref = $ngo->targets; # ... [ { type => x, id => i },...]
        map { 
            $seen{$_->{type}}{$_->{id}}++;
            $max{$_->{type}}++;
        } @$target_aref;
    }
    &$build_sets_time;

    my $intersection_time = $env->get_timer("find set intersection");
    # foreach alert, entry, (possibly others?)
    foreach my $type (keys %max) {
        my $c = $max{$type};
        # foreach id that was seen,
        foreach my $id (keys %{$seen{$type}} ) {
            # if the count is not the max then not a match
            next if ( $seen{$type}{$id} < $c );
            push @{$results{$type}}, $id;
        }
    }
    &$intersection_time;

    # now results = { alert => [ id1, ... ], entry => [ idx, ... ] };
    &$total_search_timer;

    return wantarray ? %results : \%results;

}


1;
