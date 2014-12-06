package Scot::Bot::Plugins;
use lib '../../../lib';
use strict;
use warnings;
use v5.10;

use Net::LDAP;
use Parallel::ForkManager;
use Data::Dumper;
use Scot::Env;
use Scot::Util::Mongo;
use Scot::Model::Plugin;
use Scot::Model::Plugininstance;
use Scot::Model::Entry;
use Scot::Model::Alert;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

use Moose;
extends 'Scot::Bot';
use namespace::autoclean;

$| = 1; #don't buffer output 

has 'env'  => (    
    is          => 'ro', 
    isa         => 'Scot::Env',
    required    => 1,  
);

my $max_processes = 10; #number of concurrent processes
my $pm;
sub process_tasks {
       my $self = shift;
       my $tasks_ref = shift;
       my $env = $self->env;
       my $mongo  = $env->mongo;

       my @tasks = @{$tasks_ref};
       foreach my $plugin_task (@tasks) {
          $plugin_task->status('assigned');
          $mongo->update_document($plugin_task);
       }
       foreach my $plugin_task (@tasks) {
          my $pid = $pm->start and next;
          if($pid == 0) {
             if($plugin_task->status eq 'assigned') {
                $self->new_task($plugin_task);
             }
             $pm->finish;
             exit;
          }
       }
}

sub run {
    my $self        = shift;

    my $env      = $self->env;
    my $mongo       = $env->mongo;
    my $interactive = $env->interactive;
    my $log         = $env->log;


    $pm = new Parallel::ForkManager($max_processes);
       my @running_tasks = $mongo->read_documents({
           collection  => "plugininstances",
           match_ref   => {status => 'running'},
           all => 1
       });
       $self->process_tasks(\@running_tasks);
    while(1) {
       $log->debug("Checking for new plugin tasks");

       my @tasks  = $mongo->read_documents({
           collection  => "plugininstances",
           match_ref   => {status => 'new'},
           all => 1
       });

       $self->process_tasks(\@tasks);       
       sleep(2);
    }
}

sub new_task {
   my $self        = shift;
   my $task        = shift;
   my $env      = $self->env;
   my $log         = $env->log;

   my $config  = $env->config;
   my $mode    = $env->mode;

   my $mongo   = Scot::Util::Mongo->new(
      'log'     => $env->log(),
      'config'  => $config->{$mode},
   );

   my $plugin_info = $mongo->read_one_document({
      collection => 'plugins',
      match_ref  => { plugin_id => $task->plugin_id}
   });

   my $run_group = $plugin_info->{run};
   my $requester = $task->{requester};
   my $requester_groups = $self->get_snl_groups($requester);       
   if(!(grep {$_ eq $run_group} @{$requester_groups})) {
      $task->status('error');
      my $error_str = '<h5>Error: User \'' . $requester . '\' is not in the group \'' . $run_group . '\' required to run this plugin</h5>Please see the owner of this group to be added.';
      $task->results($error_str);
      $mongo->update_document($task);
      my $entry_to_update = $mongo->read_one_document( {
         collection => 'entries',
         match_ref => {'entry_id'=> $task->entry_id}
      });
      $entry_to_update->controller($env);
      my $previous_body = $entry_to_update->body;
      $entry_to_update->body($error_str);
      $entry_to_update->update_data_derrived_from_body($previous_body);
      $mongo->update_document($entry_to_update);
      $env->activemq->send('activity', {
         action          => "update",
         type            => "entry",
         id              => $entry_to_update->entry_id,
         target_type     => $entry_to_update->target_type,
         target_id       => $entry_to_update->target_id,
      });
      exit;
   }

   my $file_info;
   my $file_id = $task->value;
   if($task->type eq 'file') {
      $file_info = $mongo->read_one_document({
          collection => 'files',
          match_ref  => {'file_id' => $task->value}
      });
      
   }
  

#   print 'Here is le task ' . Dumper($task);
   my $ua = LWP::UserAgent->new();
   push @{ $ua->requests_redirectable }, 'POST';
   my $option_href = $task->options;
   my %content = {};
   $content{'id'} = $task->plugininstance_id; 
   if(defined($option_href)) {
      %content =  %{$option_href};
   }
   if(defined($file_info)) {
      my $file_field = $plugin_info->file_field;
      my $file_full_path = $file_info->{'fullname'};
      my $filename = $file_info->{'filename'};
      $content{$file_field}  = [$file_full_path, $filename];
   }
   print Dumper(%content);
   my $request = POST  $plugin_info->submitURL,  Content_Type => 'multipart/form-data', Content => \%content;
#   $log->debug('submitting request to plugin ' . Dumper($request));
   my $response = $ua->request($request);
   if($response->is_success) {
      my $response_string = $response->as_string;
      my $response_body   = $response->decoded_content;
#      $log->debug('SUCCESSFUL plugin response ' . $response_string . Dumper($task));
      $task->status('running');
      $mongo->update_document($task);
      my $json    = JSON->new->relaxed(1);
      my $decoded = '';
      eval {
         $decoded = $json->decode($response_body);
         if(defined($decoded->{'id'})) {
            $task->plugininstance_id($decoded->{'id'});
         } else {
            $log->error('plugin submit did not return an id');
         }
         $mongo->update_document($task);
      };
      if ($@) {
         $log->error('ERROR unable to decode JSON response from plugin: ' . $@ ); 
         $task->status('error');
         $mongo->update_document($task);
      }


   } else {
      $log->error('ERROR plugin response ' . Dumper($response->error_as_HTML) . Dumper($task)); 
      $task->status('error');
      $mongo->update_document($task);
   }
   do {
      $task = $self->running_task($task, $mongo, $plugin_info);
   } while ($task->status eq 'running');
}


sub running_task {
   my $self        = shift;
   my $task        = shift;
   my $mongo       = shift;
   my $plugin_info = shift;
   my $env      = $self->env;
   my $log         = $env->log;

#   print 'le task that is already running' . Dumper($task);

   my $ua = LWP::UserAgent->new();
   my $id = $task->plugininstance_id;
   my $statusURL = $plugin_info->statusURL;
   $log->debug('Origional statusURL: ' . $statusURL);
   $statusURL =~ s/\%.*\%/$id/eg;
   $log->debug('Customized statusURL: ' . $statusURL);
   my $request = GET $statusURL;
#   $log->debug('getting status of plugin (request) ' . Dumper($request));
   my $response = $ua->request($request);
   if($response->is_success) {
      my $response_string = $response->as_string;
      my $response_body   = $response->decoded_content;
#      $log->debug('SUCCESSFUL plugin response ' . $response_string . Dumper($task));
      my $json    = JSON->new->relaxed(1);
      my $decoded = '';
      eval {
         $decoded = $json->decode($response_body);
         if(defined($decoded->{'status'})) {
            if(lc($decoded->{'status'}) eq 'finished' || $decoded->{'status'} eq 'running' || $decoded->{'status'} eq 'error') {
               $task->status(lc($decoded->{'status'}));
               $mongo->update_document($task);
            } else {
               $log->debug("The plugin status returned was '".$decoded->{'status'}."' which is NOT a valid status`, we'll ignore for now");
               $task->status('running');
               $mongo->update_document($task);
            }
         } else {
            $log->error("when checking on status of plugin, the plugin didn't return a status");
            $task->status('error');
            $mongo->update_document($task);
         }
      };
      if ($@) {
         $log->error('ERROR unable to decode JSON response from plugin OR update status'); 
         $task->status('error');
         $mongo->update_document($task);
      }
      eval {
         my $previous_results = $task->results;
         if(defined($decoded->{'results'}) && ($decoded->{'results'} ne $previous_results)) {
            $task->results($decoded->{'results'});
            $mongo->update_document($task);
            my $entry_to_update = $mongo->read_one_document( {
                 collection => 'entries',
                 match_ref => {'entry_id'=> $task->entry_id}
            });
            $entry_to_update->controller($env);
            my $previous_body = $entry_to_update->body;
            $entry_to_update->body($decoded->{'results'});
            $entry_to_update->update_data_derrived_from_body($previous_body);
            $mongo->update_document($entry_to_update);
            $env->activemq->send('activity', {
             action          => "update",
             type            => "entry",
             id              => $entry_to_update->entry_id,
             target_type     => $entry_to_update->target_type,
             target_id       => $entry_to_update->target_id,
           });

         } else {
            $log->error('Results not defined when checking on results plugin');
         }
      };
      if ($@) {
         $log->error('Error updating results when checking on plugin: ' . $@ );
         $task->status('error');
         $mongo->update_document($task);
      }

   } else {
      $log->error('ERROR plugin response ' . Dumper($response->error_as_HTML) . Dumper($task)); 
      $task->status('error');
      $mongo->update_document($task);
   }
   return $task;
}


sub get_snl_groups {
    my $self    = shift;
    my $user    = shift;
    my $log     = $self->log;
    my @groups  = ();

    my $ldap = Net::LDAP->new(  'sec-ldap-nm.sandia.gov',
                                'scheme'    => 'ldap' );

    my $msg     = $ldap->bind(  'cn=snlldapproxy,ou=local config,dc=gov',
                                'password'  => 'snlldapproxy');


    my $search  = $ldap->search(
        'base'      => 'ou=accounts,ou=snl,dc=nnsa,dc=doe,dc=gov',
        'filter'    => "uid=$user",
        'attrs'     => ['memberOf'],
    );
    my $membership  = $search->pop_entry();
    foreach my $attr ($membership->attributes()) {
        push @groups,
            map { /cn=(.*?),.*/; $1 } $membership->get_value($attr);
    }
    return \@groups;
}

1;
