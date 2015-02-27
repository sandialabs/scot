package Scot;

use strict;
use warnings;
use v5.10;
use Readonly;

use Carp qw(cluck longmess shortmess);
use Mojo::Base 'Mojolicious';
use Mojo::Cache;
use Time::HiRes qw(gettimeofday tv_interval);
use JSON;

use Scot::Env;

#use Scot::Util::Redis3;
#use Scot::Util::Mongo;
#use Scot::Util::ActiveMQ;
#use Scot::Util::Phantom;
#use Scot::Util::Ldap;

use Scot::Model::Audit;
use DateTime;
use DateTime::Format::Strptime;
use Data::Dumper;

no warnings 'redefine';
sub DateTime::_stringify { shift->strftime('%Y-%m-%d %H:%M:%S %Z') }

=head1 Scot.pm 

SCOT : Sandia Cyber Omni Tracker

This is the main perl module that comprises the SCOT web application.
It is a child of Mojo::Base and therefore is a Mojolicious based app.

=cut


sub startup {
    my $self    = shift;

    $| = 1;

    my $env     = Scot::Env->new( config_file => "../scot.conf" );
    $self->attr     ( env => sub { $env } );
    $self->helper   ( env => sub { shift->app->env } );

    my $log = $env->log;

    # get config
    my $config  = $env->{config};
    my $mode    = $env->mode;
    my $version = $config->{version};

    my $cache   = Mojo::Cache->new(max_keys => 100);
    $self->helper   ('cache'  => sub { $cache } );

    # session set up
    my $secret =    $config->{'session_secrets'};

    #Check Mojolicious Secret password (used to secure cookies) isn't the default
    if($secret eq 'scotpassword!') {       my @values = ("A".."Z", "a".."z", '0..9', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_');
      #generate a new secret password 20 characters long
      my $secret = '';
      $secret .= $values[rand @values] for 1..20;

      #Update the config file with the new secret
      $config->{'session_secrets'} = $secret;
      my $instdir     = $config->{'install_directory'};
      my $savePath = $instdir . "/scot.conf";
      $Data::Dumper::Terse = 1;
      open(FILE, ">$savePath") || die "Can not change Mojolicious session secret from default, error writing config file ($savePath): $!";
      print FILE Dumper($config);
      close(FILE) || die "Error closing config file: $!";

    }
    $self->secrets([$secret]);    

    $self->sessions->default_expiration ($config->{'session_expiration'});
    $self->helper   ('fs_root'    => sub { $config->{$mode}->{file_store}});
    $self->sessions->secure             (1);


    $self->log($log);

    $log->info(          "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n".
                " "x55 . "| Starting SCOT   ". $version     ."\n".
                " "x55 . "| Mode:           ". $mode        ."\n".
                " "x55 . "| Config:         ". Dumper($config->{$mode}) . "\n".
                " "x55 . "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n");

    
    $SIG{'__WARN__'} = sub {
        do {
            no warnings 'uninitialized';
            $log->warn(@_);
            unless ( grep { /uninitialized/ } @_ ) {
                $log->warn(longmess());
            }
        }
    };
    $SIG{'__DIE__'} = sub {
        $log->error(@_);
        $log->warn(longmess());
    };


=head2 Scot Application Attributes and Helpers

=over 4 


=item B<is_admin>

calling this will tell you if the user is the SCOT admin LDAP group

=cut

    $self->helper( 'is_admin'   => sub {
        my $self    = shift;
        my $groups  = $self->session('groups');
        if ( grep { /admin/ } @{$groups} ) {
            return 1;
        }
        return undef;
    });

    

    
=item B<get_json>

get JSON that was submitted with the web request

=cut

    $self->helper( 'get_json'   => sub {
        my $self    = shift;
        my $req     = $self->req;
        return $req->json;
    });

=item B<parse_json_param(I<parm_name>)>

in GET requests, submitted JSON must be in a url parameter.
e.g. http://foo.com/doit?myjson={foo: "bar"}
this function will parse it out.

=cut

    $self->helper( 'parse_json_param'   => sub {
        my $self    = shift;
        my $param   = shift;
        my $req     = $self->req;
        my $href    = {};
        my $value   = $req->param($param);
        my $log     = $self->app->log;

        $log->trace("parsing json param $param");

        if ( defined $value ) {
            my $json    = JSON->new->relaxed(1);
            $href       = $json->decode($value);
            $log->debug(Dumper($href));
            return $href;
        }
        $log->error("Param $param not defined!");
        return undef;
    });

=item B<parse_grid_settings>

this function will return a href of the grid settings passed in to 
the web app.  

=cut

    $self->helper( 'parse_grid_settings'    => sub {
        my $self    = shift;
        my $request = $self->req;
        my $setting = {};
        my $grid    = $request->param('grid');

        $log->trace("parsing grid settings");

        if ( defined $grid ) {
            my $json    = JSON->new->relaxed(1);
            $setting    = $json->decode($grid);
            return $setting;
        }
        return undef;
    });

    $self->helper( 'parse_cols_requested'   => sub {
        my $self    = shift;
        my $request = $self->req;
        my @columns = $request->param('columns');
        return \@columns;
    });

    $self->helper( 'parse_match_ref'        => sub {
        my $self    = shift;
        my $request = $self->req;

        $log->trace("parsing match_ref");

        my $match_ref   = {};
        my @ignore      = qw(columns grid);
        my @availparams = $request->param;

        foreach my $param ( @availparams ) {
            next if ( grep { /^$param$/ } @ignore );
            next if ( $param eq '' );

            $log->debug("Examining param: $param");
            my @match_values    = $request->param($param);
            $log->debug("Has values ".Dumper(\@match_values));

            if ( scalar(@match_values) > 1 ) {
                $match_ref->{$param} = { '$all' => \@match_values };
            }
            else {
                $match_ref->{$param} = $match_values[0];
            }
        }
        return $match_ref;
    });


    # routes
    my $r       = $self->routes;

    # this will catch visits to https://scotng.sandia.gov/ and 
    # direct it to /scot/home

    $r->route( '/' )      ->to( 'util-a3#login' )  ->name( 'login' );
    $r->route( '/scot' )  ->to( 'util-a3#login' )  ->name( 'login' );

    # make sure that we have passed authentication

    my $scot    = $r->under('/scot')->to('util-a3#check');

=back

=head1 API doc

 params = CGI params on the URL e.g. /scot/foobar?B<param1>=1
 input  = naked json pulled from the put or post request
 returns= what is returned via http
 notifications = what is sent out view activemq

=cut
    $scot   ->route ( '/login')
            ->via   ( 'post' )
            ->to    ( 'util-a3#login')
            ->name  ( 'login' );

    $scot   ->route ( '/home' ) 
            ->via   ( 'get' )
            ->to    ( 'controller-home#home' )
            ->name   ( 'homestats');

    $scot   ->route ( '/flair' )
            ->via   ( 'post' )
            ->to    ( 'controller-flair#scratchpad' )
            ->name  ( 'scratchpad' );

    $scot   ->route ( '/game/:type' )
            ->via   ( 'get' )
            ->to    ( 'controller-home#game' )
            ->name  ( 'game');

    $scot   ->route ( '/chat' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#chat' )
            ->name  ( 'chat' );

    $scot   ->route ( '/chat/:room' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#candy' )
            ->name  ( 'chat_candy' );

    $scot   ->route ( '/unauthorized' )
            ->to    ( 'controller-handler#unauthorized' )
            ->name  ( 'unauthorized' );

    $scot   ->route ( '/meta/get_avail_reports' )
            ->via   ( 'get' )
            ->to    ( 'controller-reports#get_avail_reports' )
            ->name  ( 'get_avail_reports');

    $scot   ->route ( '/meta/report' ) 
            ->via   ( 'put' ) 
            ->to    ( 'controller-reports#get_report' )
            ->name  ( 'get_named_report');

    $scot   ->route ( '/meta/aei_by_time' )
            ->via   ( 'get' )
            ->to    ( 'controller-reports#aei_by_time' )
            ->name  ( 'get_aei_by_time' );

    $scot   ->route ( '/meta/ee_graph' )
            ->via   ( 'get' )
            ->to    ( 'controller-reports#event_entity_connection_graph' )
            ->name  ( 'ee_graph' );

    $scot   ->route ( '/neighbors' )
            ->via   ( 'get' )
            ->to    ( 'controller-reports#neighbor_graph' ) 
            ->name  ( 'neighbor_graph' );

=over 4 

=item B<GET /scot/ihcalendar>

 params:        values:
 start          integer seconds since the unix epoch
 end            integer seconds since the unix epoch
 ---
 returns:       JSON
 [  {
        id      :   integer event_id,
        title   :   "username",
        allDay  :   js boolean, always true
        starg   :   string representation of date
    }, ...
 ]

=cut

    $scot   ->route ( '/ihcalendar' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#ihcalendar' )
            ->name  ( 'ihcalendar' );

=item B<GET /scot/current_handler>

 params:        values:
 ---
 returns:       JSON
 {
        incident_handler   :   "username"
 }, ...

=cut

    $scot   ->route ( '/current_handler' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#current_handler' )
            ->name  ( 'get_current_incident_handler' );

=item B<PUT /scot/ihcalendar/new>

 params:        values:
 handler        "username" string,
 start_date     "MM/DD/YYYY 00:00:00.00",
 end_date       "MM/DD/YYYY 00:00:00.00",
 ---
 returns:       redirect to /ng/incident_handler.html

=cut

    $scot   ->route ( '/ihcalendar/new' )
            ->via   ( 'put' )
            ->to    ( 'controller-handler#create_ihcal_entry' )
            ->name  ( 'ihcalendar_create' );

=item B<GET /scot/alertgroup/refresh/:id>

 input:         
 id             integer id value of alertgroup we are refreshing display of
 params:        values:
 ---
 returns:       JSON
 { title : "Alertgroup Status Refresh",
   action: "get",
   thing:  "alertgroup",
   id   :  id of the alertgroup being refreshed,
   stime:  time the server took to process request,
   data : {
        views       :   integer count of number of views
        viewed_by   :   {
                            username : { 
                                when    : seconds since unix epoch,
                                count   : number of views by username,
                                from    : ip addr last viewed from,
                            }, ...
                        },
        alertcount  :   integer number of alerts in alertgroup,
        alertgroup_id : integer alertgroup_id
        message_id  :   string of email Message-Id header,
        when        :   int secs since unix epoch,
        created     :   int secs since unix epoch,
        updated     :   int secs since unix epoch,
        alert_ids   :   [ int_alert_id1, inte_alert_id2, ... ],
        status      :   string of a valid status (see Scot::Model::Alertgroup)
        open        :   int number of open alerts in alertgroup,
        closed      :   int number of closed alerts in alertgroup,
        promoted    :   int number of promoted alerts in alertgroup,
        total       :   int number of total alerts in alertgroup,
        subject     :   string representation of the subject
        guide_id    :   int id of the guide for this alert
        source      :   string describing the source
    }

=cut

    $scot   ->route ( '/alertgroup/refresh/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#refresh_alertgroup_status' )
            ->name  ( 'refresh_alertgroup_status' );


=item B<POST /scot/ssearch>

 NOTE: this is a simplistic mongo string search
 params:        values:
 query          string
 ---
 returns:   ( slowly :-) ) JSON
 {
    title   :   "Search Results",
    action  :   "post",
    thing   :   "multiple",
    status  :   status of the search
    data    :   {
        tags    : {
            hits    : int,
            data    : [ {
                            tag_id  : int,
                            snippet : string,
                            tagees  : [
                                        { type: string, id: int }, ...
                                      ],
                            matched_on: "tag",
                        },...
                       ]
        },
        entries : {
            hits    : int,
            data    : [
                        {
                            entry_id    : int,
                            target_type : string,
                            target_id   : int,
                            snippet     : string,
                            matched_on  : 'entry body',
                        },...
                      ]
        },
        // not implemented yet...
        alerts:  {
            hits    : int,
            data    : ....
        }
    }
 }

=cut

    $scot   ->route ( '/ssearch' )
            ->via   ( 'post' )
            ->to    ( 'controller-search#scot_search' )
            ->name  ( 'search_scot' );

=item B<PUT /scot/promote>

 params:        values:
 none, but JSON is sent of the form:
 {
    thing   : string, // alert, event,
    id      : [int1, int2,...],
 }
 ---
 returns:       JSON
 {
    title   : "Promote $thing to $target_type",
    action  : "put",
    thing   : $target_type,     // event, incident
    id      : id of promoted thing,
    status  : "ok" | "failed",
    data    : [ 
                {
                    initial     => object type,
                    initial_id  => id of the initial object,
                    final       => object type,
                    final_id    => id of final object,
                },...
              ],
    stimer  : time server took to promote,
 }, ...
 Notifications:
 active_mq: {
    action  : "promotion",
    type    : type of the promotion, // promote an alert, this will be event.
    id      : id of the new promotion object,
 }

=cut

    $scot   ->route ( '/promote' )
            ->via   ( 'put' )
            ->to    ( 'controller-handler#promote' )
            ->name  ( 'promote_thing' );

=item B<GET /scot/task >

    params:
        grid={
            start       : int,
            limit       : int,
            sort_ref    : { colname : -1|1 }
        },
        columns=[ col1, col2,...  ],
    input:
    none
    ---
    returns:            JSON:
    {
        title   : "Task List",
        action  : "get",
        thing   : "tasks",
        status  : "ok" | "fail",
        total_records   : int,
        data    : [ 
                    { 
                        entry_id    : id,
                        task        : {
                            when    :   int seconds since epoch,
                            who     :   "username" assigned to task,
                            status  :   "open|assigned|completed",
                        },
                        is_task     : boolean,
                        body        : string,
                        body_flaired    : flaired string,
                        body_plaintext  : plain jane,
                    },...
                  ]
    notifications:
    none

=cut

    $scot   ->route ( '/task' )
            ->via   ( 'get' )
            ->to    ( 'controller-tasks#get' )
            ->name  ( 'get_list_of_tasks' );

=item B<GET /scot/entity >

    params:
        match={
            entity_value: "string" or [ "string1", "string2",... ],
            entity_type:  "string" // optional...
        }
    input:
    ---
    returns:
    json:   {
        title       : "SCOT Entity INFO",
        action      : "get",
        thing       : "entity",
        status      : "ok",
        data        : [
                        {
                            entity_id   : int,
                            entity_type : "string",
                            value       : "string",  the entity itself
                            notes       : [
                                            {
                                                who  => "username",
                                                when => int secs,
                                                text => string,
                                            },...
                                          ],
                            alerts      : [ alert_id1, alert_id2,... ],
                            events      : [ event_id1, event_id2,... ],
                            incidents   : [ incident_id1, ... ],
                            geo_data    : {

                            },
                            reputation  : {

                            },
                            block_data  : {

                            },
                        },...
                      ]
    }
    notifications:
    none

=cut

    $scot   ->route ( '/entity' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_entity_info' )
            ->name  ( 'get_entity_info' );

=item B<PUT /scot/entity >

    params:
    none    
    input:      JSON:
    {
        entity_value:   string,
        note        :   string,  "user notes"
    }
    ---
    returns:    JSON
    {
        title   : "SCOT Entity Update",
        action  : "put",
        thing   : "entity",
        status  : "ok" | "fail,
        data    : "reason for fail", # only if status is fail
    }
    notifications:
    none

=cut

    $scot   ->route ( '/entity' )
            ->via   ( 'put' )
            ->to    ( 'controller-handler#put_entity_info' )
            ->name  ( 'put_entity_info' );

=item B<GET /scot/entity/entry/:id >

    params:
    none
    input:
    none
    ---
    returns:    JSON:
    {
        title   : "Entity Data for $thing $id",
        thing   : "entity_data",
        target  : $thing,
        id      : $id,
        status  : 'ok',
        stime   : int,
        data    : {
            "entity_value1"  : {
                entity_id   : int,
                entity_type : "string",
                notes       : [ {
                                    who     => username,
                                    when    => secs since epoch,
                                    text    => string,
                                },...
                              ],
                geo_data    : {

                },
                block_data  : {

                },
                reputation  : {

                },
                alerts      : int,
                events      : int,
                incidents   : int,
            },...
        }
    }
    notifications:
    none

=cut

    $scot   ->route ( '/entity/entry/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_entity_data_for_entry' )
            ->name  ( 'get_entity_data_for_entry' );

=item B<GET /scot/groups>

    params:
    none
    input:
    none
    ---
    returns:    json:
    {
        title   : "SCOT Group List",
        action  : "get",
        thing   : "scotgroups",
        status  : "ok",
        data    : {
            groups  : [ group1, group2, ... ],
        }
    }
    notifications:
    none

=cut

    $scot   ->route ( '/groups' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#getgroups' )
            ->name  ( 'get_list_of_groups' );

=item B<GET /scot/whoami >

    params:
    none
    input:
    none
    ---
    returns: json:
    {
        title   : "whoami",
        action  : "whoami",
        user    : $user,
        status  : "no matching user", # if user doesn't exist, else
        data    : {
            user_id     : int,
            username    : string,
            tzpref      : string,
            lastvisit   : int secs since epoch
            theme       : string,
            flair       : href of flair prefs,
            display_orientation : string,
        }
    }
    notifications:
    none

=cut

    $scot   ->route ( '/whoami' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#whoami' )
            ->name  ( 'whoami' );

=item B<GET /scot/file/:id >

    params:
        (optional) download=1
        grid={start:x, limit:y, sort_ref: { col : -1 }}
        columns=[col1,col2,...]
    input:
        none
    ---
    returns:
        if param download=1, then the file is downloaded, else
        {
            title   : "File List",
            action  : "get",
            thing   : "file",
            status  : "ok",
            data    : [ {
                            file_id     : int,
                            scot2_id    : int,
                            notes       : string,
                            entry_id    : int,
                            size        : int,
                            filename    : string,
                            dir         : string,
                            fullname    : string = dir + / + filename
                            md5         : string,
                            sha1        : string,
                            sha256      : string,
                        },...
                    ]
        }
    notifications:
    none

=cut

    $scot   ->route ( '/file/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-files#get' )
            ->name  ( 'get_files' );

=item B<POST /file/upload >

    params:
        target_type=string
        target_id=int
        entry_id=int
        notes=string
        readgroups=x,readgroups=y,...
        modifygroups=a,modifygroups=b,...
    input:
    ---
    returns:    json:
    [
        { file: string, status: "ok" | "failed", reason : string if fail },...
    ]
    notifications:
    none

=cut

    $scot   ->route ( '/file/upload' )
            ->via   ( 'post' )
            ->to    ( 'controller-files#receive' )
            ->name  ( 'receive_upload' );

=item B<PUT /scot/file/:id >

    params:
    input:
    json of attributes to update
    ---
    returns:
    {
        action  : "put"
        thing   : "files",
        id      : $id,
        status  : $status,
    }
    notifications:
    none

=cut

    $scot   ->route ( '/file/:id' )
            ->via   ( 'put' )
            ->to    ( 'controller-files#update' )
            ->name  ( 'update_meta' );

=item B<GET /scot/health >

    params:
    none
    input:
    none
    ---
    returns:
    {
        title   : "Health Check",
        action  : "get",
        thing   : "health",
        status  : "ok",
        data    : {'alert_bot':int, 'etc':int, ... ],
        stimer  : int,
    }
    notifications:
    none

=cut

    $scot   ->route ( '/health' )
            ->via   ( 'get' )
            ->to    ( 'controller-health#check' )
            ->name  ( 'health' );

=item B<GET /scot/tags >

    params:
    none
    input:
    none
    ---
    returns:
    {
        title   : "Tag Autocomplete List",
        action  : "get",
        thing   : "tags",
        status  : "ok",
        data    : [ tag1, tag2, ... ],
        stimer  : int,
    }
    notifications:
    none

=cut

    $scot   ->route ( '/tags' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_tags_autocomplete' )
            ->name  ( 'get_list_of_tags' );

=item B</scot/admin/backup/:id>

  Download a specific SCOT Backup

=cut
    $scot   ->route ( '/admin/backup/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-admin#download_backup' )
            ->name  ( 'download_backup' );

            
=item B</scot/admin/backup/:id>

  Delete a specific SCOT Backup

=cut
    $scot   ->route ( '/admin/backup/:id' )
            ->via   ( 'delete' )
            ->to    ( 'controller-admin#delete_backup' )
            ->name  ( 'delete_backup' );
            
            
=item B</scot/admin/backup/>

  list SCOT backups

=cut
    $scot   ->route ( '/admin/backup' )
            ->via   ( 'get' )
            ->to    ( 'controller-admin#list_backups' )
            ->name  ( 'list_backups' );            
          
          
=item B</scot/admin/backup/>

  Start a SCOT backup

=cut
    $scot   ->route ( '/admin/backup' )
            ->via   ( 'POST' )
            ->to    ( 'controller-admin#create_backup' )
            ->name  ( 'create_backup' );            
            
            
=item B</scot/admin/backup/schedule>

  Schedule backups

=cut
    $scot   ->route ( '/admin/backup/schedule' )
            ->via   ( 'POST' )
            ->to    ( 'controller-admin#schedule_backup' )
            ->name  ( 'schedule_backup' );  
            
=item B</scot/admin/backup/:id>

  Download a specific SCOT Backup

=cut
    $scot   ->route ( '/admin/backup/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-admin#download_backup' )
            ->name  ( 'download_backup' );            

=item B</scot/admin/restore>

  scot restore from backup bundle

=cut
    $scot   ->route ( '/admin/restore' )
            ->via   ( 'post' )
            ->to    ( 'controller-admin#restore_backup' )
            ->name  ( 'restore_backup' );            
            
=item B</scot/admin/alerts/:collector>

  Scot alerts input configuration

=cut

  $scot   ->route ( '/admin/alerts/:setortest/:collector' )
          ->via   ( 'POST' )
          ->to    ( 'controller-admin#test_set_collector' )
          ->name  ( 'test_set_collector');

  $scot   ->route ( '/admin/alerts' )
          ->via   ( 'GET' )
          ->to    ( 'controller-admin#get_email_settings' )
          ->name  ( 'get_alert_collectors' );

=item B</scot/admin/stats>

Gets system stats

=cut
    $scot   ->route ( '/admin/stats/' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_stats' )
            ->name  ( 'get_stats' );


=item B</scot/admin/auth>

Get / set auth settings

=cut

    $scot   ->route ( '/admin/auth/' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_auth_settings' )
            ->name  ( 'get_auth_settings' );


=item B</scot/admin/auth/:X>

Get / set users and groups for local auth

=cut

    $scot   ->route ( '/admin/auth/user/:username' )
            ->via   ( 'put' )
            ->to    ( 'controller-admin#edit_local_user' )
            ->name  ( 'edit_local_user' );

    $scot   ->route ( '/admin/auth/user/:username' )
            ->via   ( 'post' )
            ->to    ( 'controller-admin#add_local_user' )
            ->name  ( 'add_local_user' );            

    $scot   ->route ( '/admin/auth/group/:groupname' )
            ->via   ( 'put' )
            ->to    ( 'controller-admin#edit_local_group' )
            ->name  ( 'edit_local_group' );

=item B<GET /scot/admin/auth/ldap> 

  Get LDAP settings

=cut

    $scot   ->route ( '/admin/auth/ldap/' )
 	    ->via   ( 'get' )
	    ->to    ( 'controller-admin#get_ldap' )
	    ->name  ( 'get_ldap' );

=item B<POST /scot/admin/auth/ldap> 

  Set LDAP settings.  This should only be called, after testing the LDAP settings with the test API call.

=cut

    $scot   ->route ( '/admin/auth/ldap' )
 	    ->via   ( 'post' )
	    ->to    ( 'controller-admin#set_ldap' )
	    ->name  ( 'set_ldap' );

=item B<POST /scot/admin/auth/ldap/test> 

  Test LDAP settings

=cut

    $scot   ->route ( '/admin/auth/ldap/test' )
 	    ->via   ( 'post' )
	    ->to    ( 'controller-admin#test_ldap' )
	    ->name  ( 'test_ldap' );

=item B<GET /scot/confirm/*url>

  for confirming if the user wants to go to the URL

=cut

    $scot   ->route( '/confirm/*url' )
	    ->via  ( 'get' )
	    ->to   ( 'controller-handler#confirm') 
	    ->name ( 'confirm' );


=item B<GET /scot/:thing >

    $collection = $thing . "s"

    params:
        grid={start:x, limit:y, sort_ref: { col : -1 }}
        columns=[col1,col2,...]
        filter={col: matchstring},
    input:
    none
    ---
    returns:
    {
        title   : "$collection list",
        actiont : "get",
        thing   : $thing,
        status  : "ok" | "fail"
        stime   : int,
        data    : [ { object1 }, ... ],
        columns : [ col1, col2, ... ],
        total_records : int,
    }
    notifications:
    {
        action  : "view",
        type    : $collection
    }

=cut

    $scot   ->route ( '/:thing' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get' )
            ->name  ( 'get_list_of_things' );

=item B<POST /scot/:thing >

    params:
        none    
    input:
    { json object with params listed in thing model }
    ---
    returns:
    {
        action  : "post",
        thing   : $thing,
        id      : new object id
        status  : $status
        reason  : string,
        stime   : int
    }
    notifications:
    {
        action  : "creation"
        type    : $thing
        id      : object id
        target_type : string,   # if entry
        target_id   : int,   # if entry
        is_task     : boolean,   # if entry
    }

=cut

    $scot   ->route ( '/:thing' )
            ->via   ( 'post' )
            ->to    ( 'controller-handler#create' )
            ->name  ( 'create_thing' );

=item B<GET /scot/:thing/:id >

    params:
        grid={start:x, limit:y, sort_ref: { col : -1 }}
        columns=[col1,col2,...]
        filter={col: matchstring},
    input:
    none
    ---
    returns: 
    {
        title   : "View One $thing $id",
        status  : "ok",
        action  : "get_one",
        thing   : $thing,
        id      : $id,
        data    : { hash of object requested }
    }
    notifications:
    none 

=cut

    $scot   ->route ( '/:thing/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_one' )
            ->name  ( 'get_one_thing' );

=item B<DEL /scot/:thing/:id >

    params:
    input:
    ---
    returns:
    {
        title   : "Delete $thing",
        action  : "delete",
        thing   : $thing,
        status  : $status,
        reason  : $reason,
        stime   : int,
    }
    notifications:
    {   
        action      : "deletion",
        type        : $thing,
        id          : $id
        target_type : string,   # if entry
        target_id   : int,   # if entry
        is_task     : boolean,   # if entry
    }

=cut

    $scot   ->route ( '/:thing/:id' )
            ->via   ( 'delete' )
            ->to    ( 'controller-handler#delete' )
            ->name  ( 'delete_thing' );

=item B<PUT /scot/:thing/:id >

    params:
    input:
    { json object with params listed in thing model }
    ---
    returns:
    notifications:
    {
        action  : "update",
        type    : $thing,
        id      : $id,
    }

=cut

    $scot   ->route ( '/:thing/:id' ) 
            ->via   ( 'put' )
            ->to    ( 'controller-handler#update' )
            ->name  ( 'update_thing' );

=item B<GET /scot/viewed/:thing/:id >

    params:
        none
    input:
        none
    ---
    returns:
    {
        title   : "update view count",
        action  : "update_viewcount",
        target  : $thing,
        id      : $id,
        view_count  : new view count int,
        status  : "ok",
    }
    notifications:
    {
        action  : "view",
        viewcount   : int,
        type        : $thing,
        id          : $id,
    }

=cut

=back

=cut 

    $scot   ->route ( '/viewed/:thing/:id' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#update_viewcount' )
            ->name  ( 'update_viewcount' );

=item B<GET /scot/plugin/:type/:value >

    params:
        none
    input:
        none
    ---
    returns:
    {
        data : [
            { 

            },
            {

            }, ...
        ],
    }

=cut

    $scot   ->route ( '/plugin/:type/:value' ) 
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_plugins_list' ) 
            ->name  ( 'get_plugin_list');


    $scot   ->route ( '/sync/:collection/:since' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#sync' )
            ->name  ( 'get_triage_updates' );

    $scot   ->route ( '/get_updated/:collection/:since' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_updated' )
            ->name  ( 'get_triage_updated' );

    $scot   ->route ( '/get_updated/:collection/:since/:until' )
            ->via   ( 'get' )
            ->to    ( 'controller-handler#get_updated' )
            ->name  ( 'get_triage_updated' );

    # catch all error route
    $scot   ->route ( '/(*)' )
            ->via   ( 'get' )
            ->to    ( 'util-error#route_not_found' )
            ->name  ( 'route_not_found');

}

1;   

__END__

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=back

