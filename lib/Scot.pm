package Scot;

use strict;
use warnings;
use v5.18;

use Carp qw(cluck longmess shortmess);
use Mojo::Base 'Mojolicious';
use Mojo::Cache;
use Scot::Env;
use Data::Dumper;


=head1 Scot.pm 

SCOT : Sandia Cyber Omni Tracker

This is the main perl module that comprises the SCOT web application.
It is a child of Mojo::Base and therefore is a Mojolicious based app.

=cut


sub startup {
    my $self    = shift;
    $self->mode('development'); # remove when in prod

    my $config_file  = $ENV{'scot_config_file'} // "/opt/scot/etc/scot.cfg.pl";

    my $env     = Scot::Env->new(
        config_file => $config_file,
    );
    $self->attr     ( env => sub { $env } );
    $self->helper   ( env => sub { shift->app->env } );
    $| = 1;

    my $cache   = Mojo::Cache->new(max_keys => 100);
    $self->helper   ('cache'  => sub { $cache } );

    my $log = $env->log;
    $self->log($log);
    $self->log_startup($log);

    $self->secrets( $env->mojo_defaults->{secrets} );
    $self->sessions->default_expiration( 
        $env->mojo_defaults->{default_expiration} 
    );
    $self->sessions->secure(1);

     $self->plugin('WithCSRFProtection');
    $self->plugin('TagHelpers');


    # Note to future maintainer: 
    # hypnotoad performs preforking.  This can cause problems with DB
    # connections created in Env, IF the DB client can't handle reconnections
    # after forking.  Meerkat for mongo can, but if we have any DBI connection
    # we might have problems.

    # pull hypnotad config from $env if it exists
    my $hypno_conf  = $env->mojo_defaults->{hypnotoad};

    if ( ! defined $hypno_conf ) {
        $hypno_conf = {
            listen  => ['http://localhost:3000?reuse=1'],
            workers => 75,
            clients => 1,
            proxy   => 1,
            pidfile => '/var/run/hypno.pid',
            heartbeat_timeout => 40,
        };
    }

    $self->config(
        hypnotoad   => $hypno_conf,
    );

    # capture stuff that normally would go to STDERR and put in log
    $SIG{'__WARN__'} = sub {
        do {
            $Log::Log4perl::caller_depth++;
            no warnings 'uninitialized';
            $log->warn(@_);
            unless ( grep { /uninitialized/ } @_ ) {
                $log->warn(longmess());
            }
            $Log::Log4perl::caller_depth--;
        }
    };
    $SIG{'__DIE__'} = sub {
        if ( $^S ){
            # in eval, don't log, catch later
            return;
        }
        $Log::Log4perl::caller_depth++;
        $log->fatal(@_);
        die @_;
    };


=head2 Scot Application Attributes and Helpers

=over 4 


=item B<get_req_json>

get JSON that was submitted with the web request

=cut

    # convenience helper to get the json out of a request
    $self->helper('get_req_json'    => sub {
        my $self    = shift;
        my $req     = $self->req;
        return $req->json;
    });

=pod

@apiDefine SearchRecord
@apiSuccess {Number} id         The unique integer id of the matching thing
@apiSuccess {String} type       The name of the thing. e.g. alertgroup
@apiSuccess {Number} score      ElasticSearch scoring of match
@apiSuccess {String} snippet    The Snippet around the match

=cut


=head2 SCOT Routes

=over 4

=cut

    my $authclass   = "Controller::Auth";

    # routes
    my $r       = $self->routes;

    $r  ->route ( '/login' )   
        ->to    ( $authclass.'#login' ) 
        ->name  ( 'login' );

=pod

@api {post} /auth Request Authentication
@apiName AuthenticateUser
@apiGroup Auth
@apiVersion 2.0.0
@apiDescription submit credentials for authentication
This route is only works on Local and LDAP authentication.  RemoteUser authentication
relies on the browser BasicAuth popup.

@apiParam {String} user     username of the person attempting to authenticate
@apiParam {string} pass     password of the person attempting authentication

@apiSuccess (200) {Cookie}  Encrypted Session Cookie

=cut

    $r  ->route ( '/auth' )    
        ->via   ('post') 
        ->with_csrf_protection
        ->to    ($authclass.'#auth') 
        ->name  ('auth');

    # let apache handle the auth
    $r  ->route ( '/sso' )    
        ->to    ($authclass.'#sso') 
        ->name  ('sso');

    $r  ->route ( '/logout' )
        ->to    ($authclass."#logout")
        ->name  ('logout');
    
    # make sure that we have passed authentication

    my $auth    = $r->under('/')->to($authclass.'#check');

    # necessary to get default index.html from /opt/scot/public
    # and have it remain so that non authenticated users can see
    $r   ->get('/')
            ->to( cb => sub {
                my $c = shift;
                $log->debug("Hitting Static /");
                $c->reply->static('index.html');
            });

    # prepends /scot to the routes below
    my $scot    = $auth->any('/scot');

    $scot   ->route ('/api/v2/search')
            ->to    ('controller-search#search')
            ->name  ('search');

    # /api/v2/hitsearch?match=foo%20bar

    $scot   ->route ('/api/v2/hitsearch')
            ->to    ('controller-search#hitsearch')
            ->name  ('hitsearch');

=pod

@api {get} /scot/api/v2/game SCOT Gamefication
@apiName game
@apiGroup Game
@apiVersion 2.0.0
@apiDescription provide fun? stats on analyst behavior
@apiSuccess {Object}    -

=cut

    $scot   ->route ('/api/v2/game')
            ->to    ('controller-metric#get_game_data')
            ->name  ('game');

=pod

@api {get} /scot/api/v2/form/:type SCOT Form server
@apiName form
@apiGroup Form
@apiVersion 2.0.0
@apiDescription provide info to UI client on how to display detail view for incidents and signatures.  possibly everything later
@apiSuccess {Object}    -

=cut

    $scot   ->route ('/api/v2/form/:type')
            ->to    ('controller-api#get_form')
            ->name  ('form');

=pod

@api {get} /scot/api/v2/metric/:thing Get a metric from SCOT
@apiName metric
@apiGroup Metric
@apiVersion 2.0.0
@apiDescription Get a metric from scot db
@apiSuccess {Object}    -

=cut

    $scot   ->route ('/api/v2/metric/:thing')
            ->to    ('controller-metric#get')
            ->name  ('get');

=pod

@api {get} /scot/api/v2/graph/:thing 
@apiName metric
@apiGroup Metric
@apiVersion 2.0.0
@apiDescription Get pyramid, dhheatmap, statistics, todaystats, bullet, or alertresponse data
@apiSuccess {Object}    -

=cut

    $scot   ->route ('/api/v2/graph/:thing')
            ->to    ('controller-stat#get')
            ->name  ('get_report_json');

=pod

@api {get} /scot/api/v2/graph/:thing 
@apiName metric
@apiGroup Metric
@apiVersion 2.0.0
@apiDescription build a graph (nodes,vertices) starting at :thing :id and going out :depth connections
@apiSuccess {Object}    -

=cut

    $scot   ->route ('/api/v2/graph/:thing/:id/:depth')
            ->to    ('controller-graph#get_graph')
            ->name  ('get_graph');
=pod

@api {get} /scot/api/v2/status
@apiName metric
@apiGroup Metric
@apiVersion 2.0.0
@apiDescription give the status of the scot system
@apiSuccess {Object}    -

=cut


    $scot   ->route ('/api/v2/status')
            ->to    ('controller-metric#get_status')
            ->name  ('get_status');

=pod

@api {get} /scot/api/v2/who
@apiName metric
@apiGroup Metric
@apiVersion 2.0.0
@apiDescription like the unix who command but for SCOT
@apiSuccess {Object}    -

=cut

    $scot   ->route ('/api/v2/who')
            ->to    ('controller-metric#get_who_online')
            ->name  ('get_who_online');

=pod

@api {get} /scot/api/v2/esearch Search Scot
@apiName esearch
@apiGroup Search
@apiVersion 2.0.0
@apiDescription search SCOT data in ElasticSearch 
@apiParam {String} qstring  String to Search for in Alert and Entry records 
@apiSuccess {Object}    -
@apiSuccess {Number}    -.queryRecordCount    Number of Records Returned
@apiSuccess {Number}    -.totalRecordCount    Number of all Matching Records
@apiSuccess {Object[]}  -.records             SearchRecords returned

=cut

    $scot   ->route ('/api/v2/esearch')
            ->to    ('controller-search#newsearch')
            ->name  ('esearch');

=pod

@api {put} /scot/api/v2/command/:action Send Queue Command
@apiName send command to queue
@apiGroup Queue
@apiVersion 2.0.0
@apiDescription send the the string :command to the scot activemq topic queue

=cut

    $scot   ->route ('/api/v2/command/:action')
            ->via   ('put')
            ->to    ('controller-api#do_command')
            ->name  ('do_command');

=pod

@api {put} /scot/api/v2/wall Post a message to every logged in user
@apiName send wall message
@apiGroup Queue
@apiVersion 2.0.0
@apiDescription Post a message to the team

=cut


    $scot   ->route ('/api/v2/wall')
            ->via   ('post')
            ->to    ('controller-api#wall')
            ->name  ('wall');
=pod

@api {post} /scot/api/v2/file Upload File
@apiName File_Uploader
@apiGroup File
@apiVersion 2.0.0
@apiDescription Upload a file to the SCOT system
@apiParam {Object} - JSON of File Record.  set "sendto" attribute

=cut

    $scot   ->route ('/api/v2/file')
            ->via   ('post')
            ->to    ('controller-file#upload')
            ->name  ('update');

=pod

@api {post} /scot/api/v2/apikey get an apikey
@apiName Apikey
@apiGroup Auth
@apiVersion 2.0.0
@apiDescription Create an apikey and return it to a user

=cut

    $scot   ->route ('/api/v2/apikey')
            ->via   ('post')
            ->to    ('controller-auth#get_apikey')
            ->name  ('get_apikey');

=pod

@api {get} /scot/api/v2/cidr?cidr=1.2.3.4/24 get list of ip entities in cidr block
@apiName CIDR
@apiGroup CIDR
@apiVersion 2.0.0
@apiDescription get list of IP address entities in SCOT that match a CIDR block
@apiParam {Object} -    List of IP addresses

=cut

    $scot   ->route ('/api/v2/cidr')
            ->via   ('get')
            ->to    ('controller-api#get_cidr_matches')
            ->name  ('get_cidr_matches');

=pod

@api {post} /scot/api/v2/:thing Create thing
@apiName Create :thing
@apiGroup CRUD
@apiVersion 2.0.0
@apiDescription Create a :thing
@apiParam {Object} -     The JSON of object to create

=cut

    $scot   ->route ('/api/v2/:thing')
            ->via   ('post')
            ->to    ('controller-api#create')
            ->name  ('create');

    $scot   ->route ('/api/v2/whoami')
            ->via   ('get')
            ->to    ('controller-api#whoami')
            ->name  ('whoami');

    $scot   ->route ('/api/v2/ac/:thing/:search')
            ->via   ('get')
            ->to    ('controller-api#autocomplete')
            ->name  ('autocomplete');

=pod

@api {get} /scot/api/v2/:thing/:id View Record
@apiName Display :thing :id
@apiVersion 2.0.0
@apiGroup CRUD
@apiDescription Display the :thing with matching :id

@apiParam {String} thing         The collection you are trying to access
@apiParam {Number} id            The integer id of the :thing to display

@apiSuccess {Object}    -       The JSON representation of the thing

@apiExample Example Usage
    curl https://scotserver/scot/api/v2/alert/123

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        key1: value1,
        ...
    }

=cut

    $scot   ->route ('/api/v2/:thing/#id')
            ->via   ('get')
            ->to    ('controller-api#get_one')
            ->name  ('get_one');

=pod

@api {get} /scot/api/v2/:thing List Records
@apiName List :thing
@apiGroup CRUD
@apiVersion 2.0.0
@apiDescription List set of :thing objects that match provided params
The params passed to this route allow you to filter the list returned to you.
* If the column_name is a string column, the value of the param is placed within a / / regex search
* If the column_name is tag or source, comma seperated strings can be sent and matching records will have to have ALL tags, or sources, listed.
* If the column_name is tag or source, pipe '|' seperated strings can be sent and matching records will have to have AT Least One tags, or sources, listed.
* If the column_name is a date field, the field assumes an array of values and will search for datetimes between the least value and the greatest value of the provided array
* If the column_name is a numeric column, the following can be can sent:

  | value       | Explanation |
  | ----------- | ----------- |
  |    x        |value of column name must equal number x
  |    >=x      |value of column name must be greater or equal to x
  |    >x       |value of column name must be greater than x
  |    <=x      |value of column name must be less than or equal to x
  |    <x       |value of column name must be less than x
  |    <x\|>y    |value of column name must be less than x or greater than y
  |    >x\|<y    |value of column name must be less than y and greater than x
  |    =x\|=y\|=z  |value of column name must be equal to x or y or z

@apiParam {String} thing            The collection you are trying to access
@apiParam {String} column_name_1    condition, see above
@apiParam {String} column_name_x    condition, see above
@apiParam {Array}  columns          Array of Column Names to return
@apiParam {Number} limit            Return no more than this number of records
@apiParam {Number} offset           Start returned records after this number of records

@apiSuccess {Object}    -
@apiSuccess {Number}    -.queryRecordCount    Number of Records Returned
@apiSuccess {Number}    -.totalRecordCount    Number of all Matching Records
@apiSuccess {Object[]}  -.records             Records of type requested

@apiExample Example Usage
    curl -XGET https://scotserver/scot/api/v2/alert 

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        "records":  [
            { key1: value1, ..., keyx: valuex },
            ...
        ],
        "queryRecordCount": 25,
        "totalRecordCount": 102323
    }

=cut

    $scot   ->route ('/api/v2/:thing')
            ->via   ('get')
            ->to    ('controller-api#list')
            ->name  ('list');

=pod

@api {post} /scot/api/v2/:thing/:id/:subthing List Related Records
@apiName Get related information
@apiVersion 2.0.0
@apiGroup CRUD
@apiDescription Retrieve subthings related to the thing



Alertgroup subthings
----------
* alert
* entity
* entry
* tag
* source

Alert subthings
-----
* alertgroup
* entity
* entry
* tag
* source

Event subthings
-----
* entity
* entry
* tag
* source

Incident subthings
--------
* events
* entity
* entry
* tag
* source


@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl -XGET https://scotserver/scot/api/v2/event/123/entry

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        "queryRecordCount": 25,
        "totalRecordCount": 102,
        [
            { key1: value1, ... },
            ...
        ]
    }

=cut

    $scot   ->route ('/api/v2/:thing/:id/:subthing')
            ->via   ('get')
            ->to    ('controller-api#get_subthing')
            ->name  ('get_subthing');

=pod

@api {put} /scot/api/v2/:thing/:id Update thing
@apiName Updated thing
@apiVersion 2.0.0
@apiGroup CRUD
@apiDescription update thing 
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl -XPUT https://scotserver/scot/api/v2/event/123 -d '{"key1": "value1", ...}'

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        id : 123,
        status : "successfully updated",
    }

=cut

    $scot   ->route ('/api/v2/:thing/:id')
            ->via   ('put')
            ->to    ('controller-api#update')
            ->name  ('update');

=pod

@api {delete} /scot/api/v2/:thing/:id/:subthing/:subid Break Link
@apiName Delete a thing related to a thing
@apiVersion 2.0.0
@apiGroup CRUD
@apiDescription Delete a linkage between a thing and a related subthing.
For example, a tag "foo" may be applied to many events.  You wish to 
disassociate "foo" with event 123, but retain the tag "foo" for use with
other events.

@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl -XDELETE https://scotserver/scot/api/v2/event/123/tag/11 

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        id : 123,
        thing: "event",
        subthing: "tag",
        subid: 11,
        status : "ok",
        action: "delete"
    }

=cut

    $scot   ->route ('/api/v2/:thing/:id/:subthing/:subid')
            ->via   ('delete')
            ->to    ('controller-api#breaklink')
            ->name  ('delete');

    # delete via params, only supported for links
    $scot   ->route ('/api/v2/:thing')
            ->via   ('delete')
            ->to    ('controller-api#delete')
            ->name  ('delete-link');

=pod

@api {delete} /scot/api/v2/:thing/:id Delete Record
@apiName Delete thing
@apiVersion 2.0.0
@apiGroup CRUD
@apiDescription Delete thing 
@apiParam {String} thing The "alert", "event", "incident", "intel", etc. you wish to retrieve

@apiExample Example Usage
    curl -X DELETE https://scotserver/scot/api/v2/event/123 

@apiSuccessExample {json} Success-Response:
    HTTP/1.1 200 OK
    {
        id : 123,
        thing: "event",
        status : "ok",
        action: "delete"
    }

=cut

    $scot   ->route ('/api/v2/:thing/:id')
            ->via   ('delete')
            ->to    ('controller-api#delete')
            ->name  ('delete');

}

sub log_startup {
    my $self    = shift;
    my $log     = shift;

    $log->info(
                "============================================================\n".
        " "x55 ."| SCOT  ". $self->env->version . "\n".
        " "x55 ."| mode: ". $self->env->mode. "\n".
        " "x55 ."============================================================\n"
    );
    # $self->env->dump_env;
}

1;   

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2015.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::API>

=item L<Scot::Env>

=back

