package Scot::Controller::Search;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Redis;
use Scot::Env;
use Data::Dumper;
use Scot::Util::Mongo;
use JSON;
use HTML::Entities;
use Time::HiRes qw(gettimeofday tv_interval);

use Scot::Model::Tag;
use Scot::Model::Event;
use Scot::Model::Entry;
use Scot::Model::Alert;
use Scot::Model::Incident;
use Scot::Model::Entity;
use base 'Mojolicious::Controller';

=item C<get_response_timer>
 who says perl can't do cool things.  Here's a closure creator that will 
 start a hires timer and log elapsed time when the closure is called again.
=cut
sub get_response_timer {
    my $self    = shift;
    my $title   = shift;
    my $start   = [ gettimeofday ];
    my $log     = $self->app->log;
    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [ gettimeofday ] );
        $log->debug("----------------------");
        $log->debug("Timer: $title") if $title;
        $log->info($self->current_route." elapsed time: ". $elapsed);
        $log->debug("----------------------");
        return $elapsed;
    };
}

#sub search {
#    my $self    = shift;
#    my $log     = $self->app->log;
#    my $query   = $self->param('query');
#    $log->debug('searching elasticsearch for '.$query);
#    my %results = ();
#    my $es      = undef;
#    my $results = "not found";
#    my $status  = "fail";
#
#    eval {
#        my $es = ElasticSearch->new();
#        my $res = $es->search(
#            'index' => 'scot',
#            type  => 'entries',
#            query => {text => {text => $query}},
#            size => 5000,
#            highlight => {
#                "fields" => {
##                	"text"
#		    "text" => {"fragment_size" => 50, "number_of_gragments" => 2}
#                }
#            }
#        );
#        $status     = 'ok';
#        $log->debug(Dumper($res));
#        $results    = $res->{'hits'}->{'hits'};
#    };
#    if ($@) {
#        $log->error("Error with Elastic Search");
#        $log->error("Error Message: $@");
#    }
#
#    $self->render(
#            json    => {
#                title   => "Search Results",
#                action  => 'post',
#                thing   => 'multiple',
#                status  => $status,
#                data    => $results,
#            }
#    );
#}

sub scot_search_new {
    my $self    = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $query   = lc($self->param('query'));
    my %results = ();
    my $timer   = $self->get_response_timer("Search Top Level");
    my $page    = $self->param('page') + 0 // 0;
    my $max_results = $self->param('limit') // 200;
    my $redis   = $self->env->redis;
    my $max_per = ($max_results / 2);

    my @types   = qw(entries alerts);
    my $ft      = {};
    my $num_skipped = 0;
    my $num_processed_results = 0;
    my @chars   = split(//, $query);
    my $idx_length = 4;
    my @entry_snippets  = ();
    my @alert_snippets  = ();
    my $loops = (scalar(@chars) - ($idx_length - 1));
    for(my $i = 0; $i<$loops; $i++) {
        my $snippet = substr($query, $i, $idx_length);
        push(@entry_snippets, $snippet);
        push(@alert_snippets, $snippet);
    }
    my @alerts_tmp = $redis->do_cmd(
                        'search_entries', 'sinter', @entry_snippets);
    my @entries_tmp = $redis->do_cmd(
                        'search_alerts', 'sinter', @alert_snippets);

    my $total_results = scalar(@alerts_tmp) + scalar(@entries_tmp);
    $log->debug('got a total of ' . $total_results . ' results');
    my $num_alert = 0;
    foreach my $alert (@alerts_tmp) {
        if($num_skipped < ($max_per * $page)) {
            next;
        }
        if($max_per > 0 && $num_alert > 100) {
            last;
        }
        $num_alert++;
        push @{$ft->{'alerts'}}, ($alert+0);
    }
    my $num_entry = 0;
    $num_skipped = 0;
    foreach my $entry (@entries_tmp) {
        if($num_skipped < ($max_per * $page)) {
            next;
        }
        if($max_per > 0 && $num_entry > 100) {
            last;
        }
        $num_entry++;
        push @{$ft->{'entries'}}, ($entry+0);
    }

    $log->debug("processed:".$num_processed_results . Dumper($ft));

    my $id_mapping   = {'alerts' => 'alert_id', 'entries' => 'entry_id'};
    my $body_mapping = {'alerts' => 'searchtext','entries' => 'body_plaintext'};
    my $mongo_timer  = $self->get_response_timer("Mongo Timer for search");
    foreach my $type (keys %{$ft}) {
        $log->debug("Type=".$type);
        my @ids = @{$ft->{$type}};
        my $key_name = $id_mapping->{$type};
        my $match_ref = {
            collection  => $type,
            match_ref   => {$key_name => { '$in' => \@ids }}
        };
        #   $log->debug("ids:".Dumper($match_ref));
        my $docs_cursor = $mongo->read_documents($match_ref);
        while (my $doc = $docs_cursor->next_raw) {
            my $id = $doc->{$id_mapping->{$type}};
            my $txt = $doc->{$body_mapping->{$type}};
            my $snippet = $self->get_snippet($query, $txt);
            # $log->debug('id='.$id.', txt='.$txt.', snippet='.$snippet);
            if($snippet ne '') {
                my $target_type = $doc->{'target_type'};
                my $target_id  = $doc->{'target_id'};
                if($type eq 'alerts') {
                    $target_type = 'alertgroup';
                    $target_id   = $doc->{'alertgroup'};
                }
                $target_id = $target_id + 0;  
                push @{$results{$target_type}->{$target_id}->{'res'}}, {
                    'id' => $id,
                    'snippet'     => $snippet,
                };
            }
        }
    }

    my @alerts = keys %{$results{'alert'}};
    @alerts = map { $_ + 0 } @alerts;
    my $alt_match_ref = {
        collection => 'alerts',
        match_ref  => {
            alert_id => { '$in' => \@alerts}
        }
    };
    #$log->debug("alt_match_ref " . Dumper($alt_match_ref));
    my $alt_cursor = $mongo->read_documents($alt_match_ref);
    while( my $alert = $alt_cursor->next_raw) {
        my $alertgroup_id = $alert->{'alertgroup'};
        my $alert_id = $alert->{'alert_id'};
        my $ress = $results{'alert'}->{$alert_id}->{'res'};
        my $snippet = '';
        foreach my $snip (@{$ress}) {
            $snippet .= $snip->{'snippet'};
        }
        push @{$results{'alertgroup'}->{$alertgroup_id}->{'res'}}, {
            'id' => $alert->{'alert_id'},
            'snippet' => $snippet
        }

    }
    delete $results{'alert'};
    &$mongo_timer;
    foreach my $target_type (keys %results) {
        my @keys = keys %{$results{$target_type}};
        @keys = map { $_ + 0 } @keys;
        my $match_ref = {
            collection => $target_type.'s',
            match_ref  => { $target_type.'_id' => { '$in' => \@keys }}
        };
        # $log->debug("Match_ref for subjects " . Dumper($match_ref));
        my $cursor = $mongo->read_documents($match_ref);
        while (my $doc = $cursor->next_raw) {
            my $id = $doc->{$target_type.'_id'};
            my $subject = $doc->{'subject'};
            $results{$target_type}->{$id}->{'subject'} = $subject;
        }
    }
    &$timer;
#   $log->debug("results are ".Dumper(\%results));

        my $href    = \%results;
        $self->render(
            json    => {
                title   => "Search Results",
                action  => 'post',
                thing   => 'multiple',
                status  => 'ok',
                data    => $href,
                total_results => $total_results
            }
        );
}


sub scot_search {
    my $self    = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $query   = lc($self->param('query'));
    my %results = ();
    my $timer   = $self->get_response_timer("Search Top Level");
    my $page    = $self->param('page') // 0;
    my $max_results = $self->param('limit') // 200;

    my $max_per = ($max_results / 2);
    $log->debug("Search SCOT for: $query\n");
my $redis = Redis->new;

$page = ($page + 0);
my @types = ('entries', 'alerts');
my $ft = {};
my $num_skipped = 0;
my $num_processed_results = 0;


my @chars = split(//, $query);
my $idx_length = 4;
my @entry_snippets = ();
my @alert_snippets = ();

my $loops = (scalar(@chars) - ($idx_length - 1));
for(my $i = 0; $i<$loops; $i++) {
  my $snippet = substr($query, $i, $idx_length);
  push(@entry_snippets, ''.$snippet);
  push(@alert_snippets, ''.$snippet);
}
$redis->select(1);
$log->debug( "alert-snippets".Dumper(@alert_snippets));
my @alerts_tmp = $redis->sinter(@alert_snippets);
$redis->select(0);
my @entries_tmp = $redis->sinter(@entry_snippets);
my $total_results = scalar(@alerts_tmp) + scalar(@entries_tmp);
$log->debug('got a total of ' . $total_results . ' results');
my $num_alert = 0;
foreach my $alert (@alerts_tmp) {
  if($num_skipped < ($max_per * $page)) {
    next;
  }
  if($max_per > 0 && $num_alert > 100) {
    last;
  }
  $num_alert++;
  push @{$ft->{'alerts'}}, ($alert+0);
}
my $num_entry = 0;
$num_skipped = 0;
foreach my $entry (@entries_tmp) {
  if($num_skipped < ($max_per * $page)) {
    next;
  }
  if($max_per > 0 && $num_entry > 100) {
    last;
  }
  $num_entry++;
  push @{$ft->{'entries'}}, ($entry+0);
}

#	         push @{$ft->{$type}}, ($ent+0);
$log->debug("processed:".$num_processed_results . Dumper($ft));
my $id_mapping = {'alerts' => 'alert_id', 'entries' => 'entry_id'};
my $body_mapping = {'alerts' => 'searchtext', 'entries' => 'body_plaintext'};
my $mongo_timer = $self->get_response_timer("Mongo Timer for search");
foreach my $type (keys %{$ft}) {
   $log->debug("Type=".$type);
   my @ids = @{$ft->{$type}};
   my $key_name = $id_mapping->{$type};
   my $match_ref = {
      collection  => $type,
      match_ref   => {$key_name => { '$in' => \@ids }}
   };
#   $log->debug("ids:".Dumper($match_ref));
   my $docs_cursor = $mongo->read_documents($match_ref);
   while (my $doc = $docs_cursor->next_raw) {
     my $id = $doc->{$id_mapping->{$type}};
     my $txt = $doc->{$body_mapping->{$type}};
     my $snippet = $self->get_snippet($query, $txt);
    # $log->debug('id='.$id.', txt='.$txt.', snippet='.$snippet);
     if($snippet ne '') {
        my $target_type = $doc->{'target_type'};
        my $target_id  = $doc->{'target_id'};
        if($type eq 'alerts') {
          $target_type = 'alertgroup';
          $target_id   = $doc->{'alertgroup'};
        }
        $target_id = $target_id + 0;  
        push @{$results{$target_type}->{$target_id}->{'res'}}, {
           'id' => $id,
   	   'snippet'     => $snippet,
        };
     }
   }
}

my @alerts = keys %{$results{'alert'}};
@alerts = map { $_ + 0 } @alerts;
my $alt_match_ref = {
   collection => 'alerts',
   match_ref  => {
     alert_id => { '$in' => \@alerts}
   }
};
#$log->debug("alt_match_ref " . Dumper($alt_match_ref));
my $alt_cursor = $mongo->read_documents($alt_match_ref);
while( my $alert = $alt_cursor->next_raw) {
  my $alertgroup_id = $alert->{'alertgroup'};
  my $alert_id = $alert->{'alert_id'};
  my $ress = $results{'alert'}->{$alert_id}->{'res'};
  my $snippet = '';
  foreach my $snip (@{$ress}) {
    $snippet .= $snip->{'snippet'};
  }
  push @{$results{'alertgroup'}->{$alertgroup_id}->{'res'}}, {
     'id' => $alert->{'alert_id'},
     'snippet' => $snippet
  }

}
delete $results{'alert'};
 &$mongo_timer;
foreach my $target_type (keys %results) {
  my @keys = keys %{$results{$target_type}};
  @keys = map { $_ + 0 } @keys;
  my $match_ref = {
     collection => $target_type.'s',
     match_ref  => { $target_type.'_id' => { '$in' => \@keys }}
  };
 # $log->debug("Match_ref for subjects " . Dumper($match_ref));
  my $cursor = $mongo->read_documents($match_ref);
  while (my $doc = $cursor->next_raw) {
    my $id = $doc->{$target_type.'_id'};
    my $subject = $doc->{'subject'};
    $results{$target_type}->{$id}->{'subject'} = $subject;
  }
}
 &$timer;
#   $log->debug("results are ".Dumper(\%results));

    my $href    = \%results;
    $self->render(
        json    => {
            title   => "Search Results",
            action  => 'post',
            thing   => 'multiple',
            status  => 'ok',
            data    => $href,
            total_results => $total_results
        }
    );
}

sub search_collection   {
    my $self        = shift;
    my $collection  = shift;
    my $query       = shift;
    my $match_refs  = shift;
    # return { hits => x, data => {} }
    my $class   = "search_".$collection;
    return $self->$class($query, $match_refs->{$collection});
}

sub search_tags {
    my $self        = shift;
    my $query       = shift;
    my $match_ref   = shift;
    my $mongo       = $self->mongo;
    my $log         = $self->app->log;
    my $cursor      = $mongo->read_documents({
        collection  => 'tags',
        match_ref   => $match_ref,
    });
    my @data    = ();
    while ( my $href    = $cursor->next_raw ) {
        push @data, {
            tag_id      => $href->{tag_id},
            snippet     => $href->{text},
            tagees      => $href->{taggees},
            matched_on  => "tag",
        };
    }
    return { hits => scalar(@data), data => \@data };
}

sub search_entries {
    my $self        = shift;
    my $query       = shift;
    my $match_ref   = shift;
    my $mongo       = $self->mongo;
    my $log         = $self->app->log;

#    $log->debug("Searching Entries for ". Dumper($match_ref));

    my $cursor      = $mongo->read_documents({
        collection  => 'entries',
        match_ref   => $match_ref,
    });
    my @data    = ();
    while ( my $href    = $cursor->next_raw ) {
        my $snippet = $self->get_snippet($query, $href->{body_plaintext});
        push @data, {
            id          => $href->{entry_id},
            target_type => $href->{target_type},
            target_id   => $href->{target_id},
            snippet     => $snippet,
            matched_on  => 'entry body',
        };
    }
    return { hits => scalar(@data), data => \@data };
}

sub max {
  my $num1 = shift;
  my $num2 = shift;
  if($num1 > $num2) {
     return $num1;
  } else {
     return $num2;
  }
}

sub get_snippet {
    my $self    = shift;
    my $query   = shift;
    my $text    = shift;
    my $mstring = shift;
    my $log     = $self->env->log;
    my $timer   = $self->env->get_timer("Snippet for $query");

    my $snippet_side_len = 50;
    my $pos = index(lc($text), lc($query));
    my $chosen_snippet = '';
#    $log->debug('pos is '.$pos);
    if($pos >= 0) {
      
      $chosen_snippet = substr($text, max($pos-$snippet_side_len, 0), ($snippet_side_len * 2 + length($query)));
    } else { return ''; }
    my $quoted_search_text  = quotemeta($query);
    
    $chosen_snippet = encode_entities($chosen_snippet);
    $chosen_snippet =~ s/($quoted_search_text)/<span style="background-color:yellow">$1<\/span>/gi;
    &$timer();
    return $chosen_snippet;
}

sub search_alerts {
    my $self        = shift;
    my $query       = shift;
    my $match_ref   = shift;
    my $mongo       = $self->mongo;
    my $log         = $self->app->log;
    my $cursor      = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => $match_ref,
    });

    my @data    = ();
    while ( my $href    = $cursor->next_raw ) {
        my $snippet = $self->get_snippet($query, $href->{searchtext});
        push @data, {
            id          => $href->{alert_id},
            target_type => "alertgroup",
            target_id   => $href->{alertgroup},
            snippet     => $snippet,
            matched_on  => "alert",
        };
    }
    return { hits => scalar(@data), data=> \@data };
}
    

sub filter {
    my $self        = shift;
    my $collection  = shift;
    my $aref        = shift;
    my @data        = ();
    my $log         = $self->app->log;

    $log->debug("FILTERING SEARCH RESULTS");

    foreach my $t (@$aref) {
        $log->debug("t is " . ref($t) . " => ".Dumper($t));
        if ($collection eq "tags") {
            push @data, { tag_id => $t->tag_id, text => $t->text,};
        }
        if ($collection eq "events") {
            push @data, { event_id => $t->event_id, subject => $t->subject };
        }
        if ($collection eq "entries") {
            push @data, { entry_id => $t->entry_id, target_type => $t->target_type, target_id => $t->target_id};
        }
        if ($collection eq "alerts") {
            $log->debug("filtering an alert");
            push @data, { alert_id => $t->alert_id, subject => $t->subject};
#            $log->debug("data is now ".Dumper(@data));
        }
        if ($collection eq "incidents") {
            push @data, { incident_id => $t->incident_id, subject => $t->subject};
        }
    }
    return \@data;
}

1;




