package Scot::Roles::Searchable;

use Moose::Role;
use Data::Dumper;

=item 
    this role will allow an object to submit itself to various search
    capabilities in scot
=cut

requires 'log';


sub get_snippets {
  my $self = shift;
  my $text = lc(shift);
  my $controller = $self->controller;
  
  my $len = $controller->fulltext_ngram_length;
  my $seen = {};
  for(my $i=0; $i<length($text); $i++) {
    my $snippet = substr $text, $i, $len;
    $seen->{$snippet} = 1;
  }
  return $seen;
}

=item remove_from_search_index 

  Removes object from fulltext search index

=cut



sub remove_from_search_index {
  my $self      = shift;
  my $controller = $self->controller;
  my $log	= $self->log;
  my $type;
  my $id;
  

  my $len = $controller->fulltext_ngram_length;
  $log->debug("Removing from fulltext index");
  if(ref($self) eq "Scot::Model::Entry") {
     $type = 'entries';
     $id   = ($self->entry_id + 0);
  } elsif (ref($self) eq "Scot::Model::Alert") {
     $type = 'alerts';
     $id   = ($self->alert_id + 0);
  }

  my $remove_old_entry_info = {
     collection  => 'fulltext'.$len,
     match_ref   => {$type => $id},
     data_ref    => {'$pull' => {$type => $id}},
  };
 
}

=item update_search_index

Update the fulltext index search done using n-grams

=cut

sub get_origtext {
    my $self    = shift;
    my $origobj = shift;

    if(ref($self) eq "Scot::Model::Entry") {
        return $origobj->{'body_plaintext'};
    } 
    elsif (ref($self) eq "Scot::Model::Alert") {
        return $origobj->{'searchtext'};
    }
}

sub get_text {
    my $self = shift;
    if(ref($self) eq "Scot::Model::Entry") {
        return $self->body_plaintext;
    } 
    elsif (ref($self) eq "Scot::Model::Alert") {
        return $self->searchtext;
    }
}

sub get_type {
    my $self = shift;
    if(ref($self) eq "Scot::Model::Entry") {
        return 'entries';
    } 
    elsif (ref($self) eq "Scot::Model::Alert") {
        return 'alerts';
    }
}

sub get_id {
    my $self = shift;
    if(ref($self) eq "Scot::Model::Entry") {
        return ($self->entry_id + 0);
    } 
    elsif (ref($self) eq "Scot::Model::Alert") {
        return ($self->alert_id + 0);
    }
}

sub update_search_index {
  my $self         = shift;
  my $origobj      = shift;
  my $controller   = $self->controller;
  my $log          = $self->log;
  my $mongo        = $controller->mongo;

  $log->debug("Updating fulltext index");
  #extract new text from object & previous text
  my $text = $self->get_text();
  my $type = $self->get_type();
  my $orig_text = $self->get_origtext($origobj);
  my $id = $self->get_id();

  #what collection are we writing to
  my $len = $controller->fulltext_ngram_length;  #length of n-grams
  my $collection = 'fulltext'.$len;

  #get snippet hashes for old and new text
  my $orig_seen = $self->get_snippets($orig_text);
  my $seen = $self->get_snippets($text);

  my @add_snippets = ();
  my @remove_snippets = ();

  #find snippets in new hash that aren't in old hash 
  foreach my $new_key (keys %{$seen}) {
    if($orig_seen->{$new_key} != 1) {
       push @add_snippets, $new_key;
    }
  }
  #find snippets in old hash that aren't in new hash
  foreach my $old_key (keys %{$orig_seen}) {
    if($seen->{$old_key} != 1) {
       push @remove_snippets, $old_key;
    }
  }

 #add all new snippets found to the DB 
 foreach my $snippet (@add_snippets) {
     my $add_new_entry_info = {  #push this entry into list of snippet
        collection => $collection,
        match_ref  => {'value' => $snippet},
        data_ref   => {'$push' => {$type => $id }}
     };
     $mongo->apply_update($add_new_entry_info, {'upsert' => 1});
  }
  #remove old snippets (if any) from the DB
  if(scalar(@remove_snippets) > 0) {
     my $remove_snippet  = {
        collection => $collection,
        match_ref  => {'value' => {'$in' => \@remove_snippets}},
        data_ref   => {'$pull' => {$type => $id}}
     };
     $mongo->apply_update($remove_snippet);
  }
  
}

sub remove_self_from_search {
    return;
}


1;
