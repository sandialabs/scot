package Scot::Controller::Admin;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Scot::Env;
use Data::Dumper;
use JSON;
use File::Slurp;
use Crypt::PBKDF2;
use Number::Bytes::Human qw(format_bytes);
use Config::Crontab;
use DateTime::Cron::Simple;
use Mail::IMAPClient;
use Readonly;
use base 'Mojolicious::Controller';


=head1 Scot::Controller::Admin

Admin request routes go through this controller.
I am type Mojolicious::Controller

=head2 Methods / Routes

=over 4

=item C<get_services>

return the status of all Scot services

ID 5
GET /scot/admin/service
-Status of all services
--DataType = JSON
=This will be used to populate list of services on admin page & get service status updates
#This is what the returned JSON will look like
Data {
    Service Name {
        Status => ENUM('RUNNING', 'STOPPED', 'ERROR', 'STARTING')
        Error => 'Error string here'
    }
}
#Note: I'm making this a hash since I might want to add more information about the service later.
#Note: This will also allow me to reference services by name, making it easy to re-check the status of a service

=cut

sub get_services {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my %data    = ();

    # do the stuff 

    $self->render(
        json    => {
            title   => "SCOT services",
            status  => 'ok',
            action  => 'get',
            data    => \%data,
        }
    );
}

=item C<command_service>

this route will send commands to a service
PUT /scot/admin/service/:service_name/:action
-Alter (stop, start, restart) a service
=Used to stop, start, or restart a service when an admin click the appreopreate button
#This is what the returned JSON will look like
Status: ENUM('SUCCESS', 'ERROR'), Error: 'error string here'

=cut
#Commented out as we do not support this right now, but maybe in the future -Nick
#sub command_service {
#    my $self    = shift;
#    my $env     = $self->env;
#    my $log     = $env->log;
#    my $status  = 'error';
#    my $error   = '';
#
#    my $service = $self->stash('service_name');
#    my $action  = $self->stash('action');
#
#    my $supported_services  = $env->commandable_services;
#    my $supported_actions   = $env->supported_actions;
#
#    if ( grep /$service/ @$supported_services ) {
#        if ( grep /$action/ @$supported_actions ) {
#            my $method  = $action . "_" . $service;
#            $status = $self->$method();
#        }
#        else {
#            $log->error("action $action not supported!");
#            $error = "unsupported action";
#        }
#    }
#    else {
#        $log->error("You can not command service $service");
#        $error = "unsupported service";
 #   }
 #   
 #   $self->render(
 #       json    => {
 #           title   => 'SCOT command service',
 #           status  => $status,
 #           error   => $error,
 #       }
 #   );
#}

=item C<add_local_user>

This route will be used to add new local users
POST /scot/admin/auth/user
-Add New user

=cut

sub add_local_user {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $json    = $self->get_json();
    my $user    = $mongo->read_one_document({
        collection => 'users',
        match_ref  => {'username' => $json->{'username'}}
    });

    if (defined($user)) {
        $self->render(json => {
            'status'    => 'Error', 
            'data'      => { 'reason' => 'User already exists'},
        }, status => '406');   
        return 1;
    }

    my $pbkdf2 = Crypt::PBKDF2->new(
        hash_class  => 'HMACSHA2',
        hash_args   => { sha_size => 512 },
        iterations  => 10000,
        salt_len    => 15,
    );

    my $hash        = $pbkdf2->generate($json->{'password'});
    my $new_user    = Scot::Model::User->new({
       username => $json->{'username'},
       hash => $hash,
       local_acct => 1,
       active   => 1,
       fullname => $json->{'fullname'},
       groups   => $json->{'groups'}
    });
    $mongo->create_document($new_user);
    $self->render(json => { 'status' => 'ok'});
}


=item C<edit_local_user>

This route will be used to edit existing local users
PUT /scot/admin/auth/user
-edit current local user

=cut

sub edit_local_group {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $json    = $self->get_json();
    my $hash;

    my $users = $json->{'users'};

    $mongo->apply_update({
        collection => 'users',
        match_ref  => {'groups' => $json->{'groupname'}},
        data_ref   => {'$pull'  => {'groups' => $json->{'groupname'}}},
    }, {'multiple' => 1}
    );
     $mongo->apply_update({
        collection => 'users',
        match_ref  => {'username' => {'$in' => $json->{'users'}}},
        data_ref   => {'$addToSet'  => {'groups' => $json->{'groupname'}}}
    }, {'multiple' => 1}
    );
    $self->render(json => { 'status' => 'ok'});

}

=item C<edit_local_group>

This route will be used to edit new or existing groups
PUT /scot/admin/auth/group
-edit a local group membership

=cut

sub edit_local_user {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $json    = $self->get_json();
    my $hash;

    my $user    = $mongo->read_one_document({
        collection => 'users',
        match_ref  => {'username' => $json->{'username'}},
    });

    if(defined($user)) {
        
    }

    if(defined($json->{password})) {
        my $pbkdf2 = Crypt::PBKDF2->new(
            hash_class => 'HMACSHA2',
            hash_args => {
                sha_size => 512
            },
            iterations => 10000,
            salt_len => 15,
        );
        $user->hash($pbkdf2->generate($json->{'password'}));
    }

    $user->fullname($json->{'fullname'});

    if($json->{'active'} == 0) {
        $user->active(0);
    } 
    else {
        $user->active(1);
        $user->lockouts(0);
    }

    $user->groups($json->{'groups'});
    $mongo->update_document($user);
    $self->render(json => { 'status' => 'ok'});

}

=item C<list_backups>

This lists backups currently on the SCOT system

=cut

sub list_backups {
    my $self = shift;
    my $instdir = $self->env->config->{'install_directory'};
    my $backup_dir = $instdir."/backups/";
    
    my $files = ();
    my $fh;

    opendir($fh, $backup_dir);

    while (my $file = readdir($fh)) {
        if ($file =~ /.+\.tgz$/) {
            my $bytes   = -s $backup_dir.$file;
            my $created = ( stat $backup_dir.$file )[9];
            (my $id)    = $file =~ /(.+)\.tgz$/;
            push @{$files}, {
                'filename'      => $file, 
                'size'          => $bytes, 
                'size_human'    => format_bytes($bytes), 
                'created_epoch' => $created, id=>$id
            };
        }
   }
   
    #edit crontab belonging to webserver user
    #my $owner    = (split /\s/,`whoami`)[0]; 
    #my $ct       = new Config::Crontab( -owner  => $owner );
    #$ct->read;
    #my $re       = 'backup.sh';
    #my ($event) = $ct->select(-command_re => $re);
    #my $schedule = substr(
    #    $event->data, 
    #    0, 
    #    lenth($event->data) - length($event->{_command})
    #);
    my $cron = $self->get_cron('backup.sh');
    $self->render(json => { 'data' => {'files' =>$files, 'cron' => $cron}});
}

=item C<create_backup>

This creates a backup on demand and places it in the backup directory

=cut

sub create_backup {
    my $self            = shift;
    my $instdir         = $self->env->config->{'install_directory'};
    my $backup_program  = $instdir."/bin/backup.sh &";
    my $response        = `$backup_program`;
    $self->render(json => { 'success' => 'ok'});
}

=item C<delete_backup>

This deletes a backup on that exists on the server

=cut

sub delete_backup {
    my $self        = shift;
    my $id          = $self->param('id');
    my $instdir     = $self->env->config->{'install_directory'};
    my $backup_dir  = $instdir."/backups/";
    my $file        = $backup_dir.$id.".tgz";
    
    if (!($id =~ /^[0-9a-zA-Z]+$/)) {
        $self->render(json => {'error' => 'invalid ID'});
        return 0;
    }   
    unlink($file);
    $self->render(json => { 'success' => 'ok'});
}



=item C<restore_backup>

This restores a backup

=cut

sub restore_backup {
    my $self        = shift;
    my $instdir     = $self->env->config->{'install_directory'};
    my $restore_dir = $instdir."/restore/";
    my $file        = $restore_dir."restore.tgz";
    my $restore_program = $instdir."/bin/restore.sh";
    my @uploads     = $self->req->upload('upload');
    my $upload      = $uploads[0]; # was @uploads[0] but changed since perl kept bitching
    if ( -e $file) {  #delete any old restore
        unlink($file);
    }

    mkdir($restore_dir, 0755);
    $upload     = $upload->move_to($file);
    my $response = `$restore_program`;
    
    $self->render(json => { 'status' => 'ok'});
}

=item C<download_backup>

This will allow the admin to download a full SCOT backup file

=cut

sub download_backup {
    my $self    = shift;
    my $id      = $self->param('id');
    my $instdir = $self->env->config->{'install_directory'};

    if (!($id =~ /^[0-9a-zA-Z]+$/)) {
        $self->render(json => {'error' => 'invalid ID'});
        return 0;
    } 
    my $filename    = $id.".tgz";
    my $path        = $instdir."/backups/".$filename;
    $self->res->content->headers->header( 
        'Content-Type', "application/x-download; name=\"$filename\""
    ); 
    $self->res->content->headers->header( 
        'Content-Disposition', "attachment;filename=\"$filename\""
    ); 
    my $file = read_file($path);
    $self->render(data=>$file);
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };


=item C<schedule_backup>

  Schedule a backup and/or change backup schedule settings

=cut

sub schedule_backup {
    my $self   = shift;
    my $json  = $self->get_json();
    my $result;
    my $log = $self->env->log;
    my $instdir = $self->env->config->{'install_directory'};

    $log->debug("The JSON " . Dumper($json));

    my $schedule = $json->{'schedule'};
    #Basic regex check to preventy Command Injection
     if(!($schedule =~ /^(((([\*]{1}){1})|((\*\/){0,1}(([0-9]{1}){1}|(([1-5]{1}){1}([0-9]{1}){1}){1}))) ((([\*]{1}){1})|((\*\/){0,1}(([0-9]{1}){1}|(([1]{1}){1}([0-9]{1}){1}){1}|([2]{1}){1}([0-3]{1}){1}))) ((([\*]{1}){1})|((\*\/){0,1}(([1-9]{1}){1}|(([1-2]{1}){1}([0-9]{1}){1}){1}|([3]{1}){1}([0-1]{1}){1}))) ((([\*]{1}){1})|((\*\/){0,1}(([1-9]{1}){1}|(([1-2]{1}){1}([0-9]{1}){1}){1}|([3]{1}){1}([0-1]{1}){1}))|(jan|feb|mar|apr|may|jun|jul|aug|sep|okt|nov|dec)) ((([\*]{1}){1})|((\*\/){0,1}(([0-7]{1}){1}))|(sun|mon|tue|wed|thu|fri|sat)))$/)) {
        $log->debug('Regex does not validate cron schedule input from user');
        return -1;
    }

    #Max num GBs backups can take in total
    my $max_disk = $json->{'max_disk'};
    if (!($max_disk eq '' || $max_disk =~ /\d+/)) {
        $log->debug('max_disk must be empty or a number');
        return -1;
    }

    #edit crontab belonging to webserver user
    my $owner   = (split /\s/,`whoami`)[0]; 
    my $ct      = new Config::Crontab( -owner  => $owner );
    $ct->read;
    my $re      = 'backup.sh';
    my $event_exists = $ct->select(-command_re => $re);
    #pass in max GBs total as optional arg to backup script
    my $fullpath =  $instdir . '/bin/backup.sh' . ' ' . $max_disk;  

    if ($event_exists == 0) {  #add the crontab entry if it doesn't exist
        my $block       = new Config::Crontab::Block;
        my $new_event   = new Config::Crontab::Event( 
            -data => $schedule . ' ' . $fullpath  
        );

        if ( trim($new_event->{'_command'}) eq trim($fullpath)) {
            $block->last( $new_event );
            $ct->last($block);
            $ct->write;
        } 
        else {
            $log->debug('secondary crontab validation failed');        
            return -1;
        }
        $ct = new Config::Crontab( -owner  => $owner );
        $ct->read;
    }
    my ($event) = $ct->select(-command_re => $re);

    
    $event->data($schedule . ' ' . $fullpath  ); #Update schedule
    if( trim($event->{'_command'}) ne trim($fullpath)) {
        $log->debug('secondary crontab validation failed');        
        return -1;
    }

    if($json->{'enable_backups'}) {  #Enable or disable entry
        $event->active(1);
    } 
    else {
        $event->active(0);
    }
    
    $ct->write;
    $log->debug('wrote schedule update to cron for backup');
    $self->render(json => {status => 'success'});   
}

=item C<get_cron>

   return cron entry

=cut

sub get_cron {
    my $self  = shift;
    my $regex = shift;
    my $log   = $self->env->log;
    #edit crontab belonging to webserver user
    my $owner   = (split /\s/,`whoami`)[0]; 
    my $ct      = new Config::Crontab( -owner  => $owner );
    $ct->read;
    my ($event) = $ct->select(-command_re => $regex);

    my $active = 0;
    my $schedule = '';
    my $max_disk = '';
    if(defined($event)) {
       $active = $event->active();
       $schedule = $event->{_minute} . ' ' . $event->{_hour} . ' ' . $event->{_dom} . ' ' . $event->{_month} . ' ' . $event->{_dow};
       my $temp_max = (split(' ', $event->data))[-1];
       if ($temp_max =~ /^[\d]+$/) {
          $max_disk = $temp_max;
       }
    }
    return {'active' => $active, 'schedule' => $schedule, 'max_disk' => $max_disk};

}

=item C<check_cron>

   Check cron for existance of a cronjob and whether its active

=cut

sub check_cron {
    my $self  = shift;
    my $regex = shift;
    my $log   = $self->env->log;
    #edit crontab belonging to webserver user
    my $owner   = (split /\s/,`whoami`)[0]; 
    my $ct      = new Config::Crontab( -owner  => $owner );
    $ct->read;
    my ($event) = $ct->select(-command_re => $regex);

    if(defined($event)) {
        return $event->active();
    }
    return 0;
}

=item C<edit_cron>

   Used to enable/disable Cron jobs as well as update their schedule

=cut

sub edit_cron {
    my $self        = shift;
    my $regex       = shift;
    my $active      = shift;
    my $schedule    = shift;
    my $cron_command = shift;
    my $log         = $self->env->log;

    #edit crontab belonging to webserver user
    my $owner   = (split /\s/,`whoami`)[0]; 
    my $ct      = new Config::Crontab( -owner  => $owner );
    $ct->read;
    my $event_exists = $ct->select(-command_re => $regex);

    #add the crontab entry if it doesn't exist
    if($event_exists == 0) {  
        my $block       = new Config::Crontab::Block;
        my $new_event   = new Config::Crontab::Event( 
            -data => $schedule . ' ' . $cron_command  
        );

        if ( trim($new_event->{'_command'}) eq trim($cron_command)) {
            $block->last( $new_event );
            $ct->last($block);
            $ct->write;
        } 
        else {
            $log->error('secondary crontab validation failed');        
            return -1;
        }
        $ct = new Config::Crontab( -owner  => $owner );
        $ct->read;
    }
    my ($event) = $ct->select(-command_re => $regex);

    $event->active($active);
    
    $event->data($schedule . ' ' . $cron_command  ); #Update schedule
    if( trim($event->{'_command'}) ne trim($cron_command)) {
        $log->error('secondary crontab validation failed');        
        return -1;
    }
    
    $ct->write;
}

=item C<test_ldap>

  Test LDAP settings before saving them

=cut

sub test_ldap {
    my $self   = shift;
    my $json  = $self->get_json();
    my $result;
    my $log = $self->env->log;  
    $log->debug("The JSON " . Dumper($json));

    my $config = { 
        ldap => {
            hostname    => $json->{'host'},
            dn          => $json->{'binddn'},
            password    => $json->{'bindpassword'},
            scheme      => $json->{'ldap_type'},
            searches    => {
                users_groups    => {
                    base    => $json->{'basedn'},
                    filter  => $json->{'uid'} . '=%s',
                    attrs   => [ $json->{'membership'} ],
                },
            },
        ,}
    };

    my $ldap    = Scot::Util::Ldap->new({
        config  => $config,
        log     => $log,
    });

    my $error;
    my $user_to_test     = $json->{'user_to_test'};
    my $test_user_groups = $ldap->get_users_groups($user_to_test);
    my $result_status    = 'failure';

    if ( $test_user_groups == -2 ) {
        $error  = "Could not find the LDAP server.  ".
                  "Please check your Scheme (ldap:// or ldaps://), ".
                  "hostname, port)";
    } 
    elsif($test_user_groups == -1) {
        $error = "LDAP bind authentication failed.  ".
                 "Please check 'Bind DN' and 'Bind Password'";
    } 
    elsif ($test_user_groups == -3) {
        $error = "Can't find the test user you specified.  ".
                 "Please check 'Test User' and 'Base Domain' and ".
                 "'User ID Attribute'";
    } 
    else {
        my $num_groups = scalar(@{$test_user_groups});
        if ( $num_groups >= 1) {
            $result_status = 'success';
        } 
        else {
            $error = "Found 'Test User', but this user has no groups. ".
                     "Please check your 'User ID Attribute' and ".
                     "'Membership Attr'";
        }
    }
    $result = {
        'status'    => $result_status, 
        data        => {'groups' => $test_user_groups}
    };

    if(defined($error)) {
        $result->{error} = $error;
    }
    $self->render(json => $result);
}

=item C<set_ldap>

  Save LDAP settings, will require reboot to take effect.

=cut

sub set_ldap {
    my $self = shift;
    my $json = $self->get_json();
    my $log  = $self->env->log;


    #TODO: Read in from file, not from in memory
    my $baseconfig  = $self->env->config; 
    my $mode        = $self->env->mode;
    my $ldap        = $baseconfig->{$mode}->{ldap};
    my $instdir     = $self->env->config->{'install_directory'};

    $baseconfig->{$mode}->{ldap}->{hostname} = $json->{'host'};
    $baseconfig->{$mode}->{ldap}->{dn} = $json->{'binddn'};
    $baseconfig->{$mode}->{ldap}->{password} = $json->{'bindpassword'};
    $baseconfig->{$mode}->{ldap}->{scheme} = $json->{'ldap_type'};
    $baseconfig->{$mode}->{ldap}->{searches}->{users_groups}->{base} = $json->{'basedn'};
    $baseconfig->{$mode}->{ldap}->{searches}->{users_groups}->{filter} = $json->{'uid'}. '=%s';
    $baseconfig->{$mode}->{ldap}->{searches}->{users_groups}->{attrs} = [ $json->{'membership'} ];
    
    my $savePath = $instdir . "/scot.conf";
    $Data::Dumper::Terse = 1;
    $log->debug("Saving new configuration to $savePath " . Dumper($baseconfig));
    open(FILE, ">$savePath") || die "Can not open: $!";
    print FILE Dumper($baseconfig);
    close(FILE) || die "Error closing file: $!";

    $self->render(json => {status => 'success'});
}


=item C<get_ldap>

  Get current LDAP settings

=cut

sub get_ldap {
    my $self = shift;
    my $log  = $self->env->log;

    my $data = {};

    my $baseconfig = $self->env->config; 
    my $mode   = $self->env->mode;
    
    $data->{'hostname'}  = $baseconfig->{$mode}->{ldap}->{hostname};
    $data->{'binddn'}    = $baseconfig->{$mode}->{ldap}->{dn};
    $data->{'ldap_type'} = $baseconfig->{$mode}->{ldap}->{scheme};
    $data->{'basedn'}    = $baseconfig->{$mode}->{ldap}->{searches}->{users_groups}->{base};
    my $uid = $baseconfig->{$mode}->{ldap}->{searches}->{users_groups}->{filter};
    $uid =~ s/(.*)=%s$/$1/;
    $data->{'uid'}       = $uid; 
    my @attrs = $baseconfig->{$mode}->{ldap}->{searches}->{users_groups}->{attrs};
    if(scalar(@attrs) > 0) {
        $data->{'attrs'}     = $attrs[0][0]; 
    } else {
        $data->{'attrs'} = '';
    }
    $self->render(json => {data => $data, status => 'success'});
}

=item C<test_email_settings>

  Test the email collector settings
  
=cut

sub test_email_settings {
    my $self   = shift;    
    my $json   = shift;
    my $log    = $self->env->log;
    
    my $email_username = $json->{'username'};
    my $email_password = $json->{'password'};
    my $email_hostname = $json->{'hostname'};
    my $email_port     = $json->{'port'};
    my $email_ssl      = $json->{'ssl'} == 1;

    my @options = (
            Server              => $email_hostname,
            Port                => $email_port,
            User                => $email_username,
            Password            => $email_password,
            Ssl                 => $email_ssl,
            Uid                 => 1,
            Ignoresizeerrors    => 1,
            SSL_verify_mode     => "SSL_VERIFY_NONE",
        );
    my $imap_alerts = Mail::IMAPClient->new(@options);
    if (defined($imap_alerts)) {
        $self->render(json => {'status' => 'success'});    
    } else {
        $self->render(json => {'status' => 'failure'}, status => 500);
    }
}

=item C<get_email_settings>

  Get email collector settings

=cut

sub get_email_settings {
    my $self  = shift;
    my $log   = $self->env->log;

    my $baseconfig = $self->env->config; 
    my $mode   = $self->env->mode;
    my $imap_config = $baseconfig->{$mode}->{imap};
    
    my $active = $self->check_cron('alertbot.pl');
    
    my $settings = {
        'email' => {
            'active' => $active,
            'username'     => $imap_config->{'username'},
            'port'         => $imap_config->{'port'},
            'hostname'     => $imap_config->{'hostname'}
        }
    };  

    $self->render(json => $settings);
}

=item C<set_email_settings>

  Set the email collector settings

=cut

sub set_email_settings {
   my $self  = shift;
   my $json   = shift;
   my $log   = $self->env->log;
   my $instdir = $self->env->config->{'install_directory'};


   #TODO: Read in from file, not from in memory
   $log->debug('Installdir is ' . $instdir);
   my $baseconfig = Config::Auto::parse($instdir . '/scot.conf', format => 'perl');   
   
   my $mode   = $self->env->mode;

  my $email_username = $json->{'username'};
  my $email_password = $json->{'password'};
  my $email_hostname = $json->{'hostname'};
  my $email_port     = $json->{'port'};
  if(defined($email_password) && $email_password ne '' && $email_username ne '') {
     $baseconfig->{$mode}->{email_accounts}->{$email_username} = $email_password;
  }
  $baseconfig->{$mode}->{imap}->{hostname} = $email_hostname;
  $baseconfig->{$mode}->{imap}->{port} = $email_port;
  $baseconfig->{$mode}->{imap}->{username} = $email_username;
  
  my $savePath = $instdir . "/scot.conf";
  $Data::Dumper::Terse = 1;
  $log->debug("Saving new configuration to $savePath " . Dumper($baseconfig));
  open(FILE, ">$savePath") || die "Can not open: $!";
  print FILE Dumper($baseconfig);
  close(FILE) || die "Error closing file: $!";
  $self->edit_cron('alertbot.pl', 1, '*/5 * * * *', '(cd ' . $instdir . '/bin/ && ./alertbot.pl)');
 
  $self->render(json => {'status' => 'success'});

}

=item C<set_collector>

  Set the settings for a single collector i.e. email, syslog, etc.

=cut

sub test_set_collector {
  my $self = shift;
  my $log  = $self->env->log;
  my $json  = $self->get_json();

  my $data = {};

  my $collector_name = $self->stash('collector');
  my $set_or_test = $self->stash('setortest');

  if($collector_name eq 'email') {
     if($set_or_test eq 'test') {
       return $self->test_email_settings($json);
     } elsif ($set_or_test eq 'set') {
       return $self->set_email_settings($json);
     }
  }

}

=item C<unlock_user>

  If a local user account is locked out for too many password attempts, this admin route unlocks it
 
=cut

sub unlock_user {
  my $self  = shift;
  my $log   = $self->env->log;
  my $json  = $self->get_json();
  my $mongo = $self->env->mongo;
 
   my $user = $mongo->read_one_document({
        collection => 'users',
        match_ref  => {'username' => $json->{'username'}}
   });
   if(defined($user)) {
     $user->lockouts(0);
     $user->attempts(0);
     $log->debug('ADMIN: Unlocking local user account ' + $json->{'username'});
     $mongo->update_document($user);
   }

  $self->render(json => {'status' => 'success'});

}


1;
