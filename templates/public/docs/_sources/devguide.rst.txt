Developing For SCOT
===================

SCOT Architecture
-----------------

overview of the puzzle pieces go here

SCOT Directory Map
------------------

bin/
    scripts, executables that run stand alone (not part of the webservice)
    Ex: bots, import scripts, export scripts, etc.

docs/
    text files that form documentation for SCOT
    
etc/
    configuration files for Scot go here

etcsrc/
    starting templates for your config files.

lib/
    Perl library Hierarchy

    Scot.pm - the top level mojolicious application library containing route info

    Scot/
        the top level of the Scot:: modules

        Bot/
            modules for use by scot bots

        Controller/
            modules for handling routes defined in Scot.pm

        Model/
            modules describing the data model for Scot data types

        Util/
            authentication, database, and other general utility modules

public/
    Static served files by mojolicious

    css/
        css files for scot, and frameworks

    img/
        images used by SCOT

    fonts/
        Any fonts used by the CSS go here

    lib/
        javascript 3rd party libraries 

        angular/
            angular libraries go here

        bootstrap/
            bootstrap stuff

        jquery/
            jquery stuff

    js/
        javascript that we create for scot including react components

    api/
        api documentation

    docs/
        online documentation


script/
    usually holds the mojolicious startup script

t/
    tests, tests, tests of mojolicious back end

templates/
    templates used for rendering data that was passed through mojolicious


SCOT REST API
-------------

`SCOT API Documentation. </api/index.html>`_

SCOT get API
^^^^^^^^^^^^

#. Retrieve one "thing" when you know the id::

    /scot/api/v2/event/123

    output:

    JSON object representing event 123

#. Retrieve list of "things"::

    /scot/api/v2/event

    output

    {
        queryRecordCount: 50,
        totalRecordCount: 10060,
        records: [
            { event json object 1 },
            ...
        ]
    }

#. Retrieve list of "things" based on time range::

    /scot/api/v2/event?created=1472244135&created=1472244137

#. Retrieve list of "things" based on string match::

   /scot/api/v2/event?subject=Symnatic

#. Retrieve list of "things" base on Numerical conditions

  a. matching a single number::

        /scot/api/v2/event?views=2      

        output: events with two views

  b. matching a set of numbers::

        /scot/api/v2/event?entry_count=2&entry_count=4&entry_count=6

        output: events with entry_count's of 2, 4, or 6

  c. matching everything but a number::
  
        /scot/api/v2/event?views=!1

        output: events with views not equal to 1

  d. matching everyting but a set of numbers::

        /scot/api/v2/event?views=!1&views=!2&views=!3

        output: events with views not equal to 1,2, or 3.  
        (note:  if ! appears in any element, all are treated as if they are !

  e. matching an expression::

        /scot/api/v2/event?views=4<x<8
        /scot/api/v2/event?views=4<=x<8
        /scot/api/v2/event?views=4<=x<=8
        /scot/api/v2/event?views=4<x<=8
        /scot/api/v2/event?views=9>x>=2

        output: events with views (represented by x) matching the expression
        syntax notes: the expression must be of the form some number of digit,
        followed immediately by one of the following operands: < <= > >=, the
        letter lower case x (which represents the column name) followed 
        immediately by the comparison operands, and finally followed 
        immediately by some numbe of digits.

#. Retrieve list of "things" based on Set Fields like "tag" or "source"::

    /scot/api/v2/event?tag=email&tag=malware&tag=!false_positive

    output:  list of evens with tags email and malware but not containing
     the tag false_positive

SCOT Event Queue
----------------

SCOT uses a message queue to publish events that have occurred.  This allows your
process to subscribe to be asyncronously updated and to take actions on these
event.  SCOT uses ActiveMQ, it gets the job done and just about every language under the
sun has a way to interface with it.

The message format is::

    {
        guid:   "unique_guid_string",
        action: "action_string",
        data:   {
            type:   "type_of_data_structure",
            id:     integer_id_of_data,
            who:    username,
        }
    }

:unique_guid_string:  is a requirement of the STOMP protocol and is generated

:action_string:       is a member of the following: 
                       *  "created"  = something was created
                       *  "updated"  = something was updated
                       *  "deleted"  = something was deleted
                       *  "viewed"   = something was viewed
                       *  "message"  = send a message to a subscriber

:type:              describes the data type that was operated on and is one of:
                       * alert
                       * alertgroup
                       * entry
                       * event
                       * incident
                       * intel
                    or in the case of a "message" it can be any string
                        that your client is listening for.

:id:                is an integer id for the "type" above.  
                    if sending a message, this could be the an epoch time.

:data:              is a json structure that you are free to put stuff in.

SCOT Server 
-----------

will discuss how to work in the Perl base server.  Perldocs will be linked here as well.

SCOT UI
-------

SCOT'S front end is primarily developed using React JS. See https://facebook.github.io/react/ to read more about it.

:pubdev/:           Contains files necessary to modify the React-based front end
*Note: Not all of the front end of SCOT is developed in React. Currently, the Incident Handler calendar and administration pages are written using jQuery and HTML, without React.*

SCOT has been written using the JSX format. See https://facebook.github.io/react/docs/introducing-jsx.html to read more about it. 

:JSX Libraries:         Most libraries that the SCOT JSX components (found in /pubdev/jsdev/react_components/) rely on are found in /pubdev/node_modules and can be installed/updated using npm.

:JSX Compiling:         Compiling the JSX files into a single javascript file is done by using Gulp. The file that specifies the compiling directories is /pubdev/gulpfile.js. The final file that is ultimately compiled and used is /public/scot-3.5.js

:JSX Dev:               If you would like to contribute to, or modify the front end of SCOT, you can do so by creating/modifying files in /pubdev/ and then compile your changes using gulp.

:Final HTML/JS:         The files ultimately used to display and control the front end are found in /public/
