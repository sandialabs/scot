REVL Visualization Guide
========================

Read-Eval-Viz-Loop
------------------

REVL is a tool for quickly reorganizing awkward data formats so that
you can inspect the data and use a variety of visualizations to find
interesting relationships and properties that would be hard to spot
otherwise. It works in a way similar to a powerful command line in
that you get data on one end, run it through a series of
transformations to pick out the bits you're interested in and stick
them to other bits, finally ending up with just the interesting parts
in a format that's easy to comprehend or ship off to a visualization
tool (of which many are included). Internally, REVL uses a result
monad to do the value handling, so you're actually working with a data
structure instead of raw text. In this case, this makes it quite a bit
more convenient to use than the standard command line.

Getting Started
---------------

When you open SCOT, click the ``Visualization`` link in the
navbar. This will open REVL, which will look like a big blank screen
with a little command prompt at the bottom. You will interact with
the system by typing strings of commands at the prompt and observing
the results either in the text output area (just above the prompt)
or in the visualization area (the bulk of the page, which is blank
white at this point).

Interacting with REVL
---------------------

To Get some help click in the prompt and type ``help`` (and press Enter).

Just above the prompt, you will see a text output area. You can drag
the top of this area to resize it, so drag it up now to see the REVL
default help message. This message gives a little background and
lists all currently loaded commands. If you can't remember the name
of something, you should be able to jog your memory by looking it up
here.

Now type ``help map`` at the prompt. This will display the
command-specific help for the ``map`` command, which is something you
will be using a *lot*.

REVL tries to be convenient - if it recognizes the first word you
type in a command segment to be a command, it treats it as one. If
not, it will evaluate whatever you type in the context of the shell,
which includes variable definitions, locally defined helper
functions, and the entire API behind the command system. The syntax
is coffeescript, which you can find out more about at
[[http://coffeescript.org][CoffeeScript.org]].

Type::

    [1..10] 

at the prompt and hit Enter. You will see the result
of evaluating that coffeescript value, which is

    [1,2,3,4,5,6,7,8,9,10] 

This particular trick (generating a list
of integers) is surprisingly useful for seeding queries later
on. Keep it in mind when you want to do something like look at all
of the events that came in between two other events (you can
sequence their id fields using this list, eg [1044..1102]).

Now hit the up arrow to repeat the last command, then add to the
back of it until you get this (the thing right after the list is a
single backslash character)::

    [1..10] \ (n)->n*n

After you hit enter, you'll see a list of the squares of the
integers from the fist list: ``[1,4,9,16,25,36,49,64,81,100]``. You
just used the ``map`` command. You could also have explicitly written
out the ``map`` name in front of the function definition, but this
particular command is so common that it's implied after a backslash
if no other command is specified.

Commands are chained together using the backslash ('\')
character. Normally the pipe ('|') would have been used, but in
this case it was just much simpler and more reliable to use the
backslash because the pipe is an important character in
user-defined coffeescript code, and it would have led to
significant ambiguity in parsing the commands.

Using REVL with SCOT data
-------------------------

Now we can do something interesting. Let's get all the entities
with ids from 10000 to 10100::

    entity offset:10000,limit:101

This command will take a few seconds to complete, and when it does
you'll see a list of entities in the text output. However, our plan
was foiled - our first id is not 10000, it's something else. If we
want to actually get entities with ids 10000 to 10100, we'll need
to specify those ids. Let's do that::

    [10000..10100] \ (n)->API.entity id:n

After you press Enter and wait, you'll find that you got a list of
100 somethings back, but they aren't entities. REVL uses
asynchronous calls for the API to make things a little faster. This
is hidden when you use the top level commands because the shell
knows to wait when the result is a promise, but when you make calls
directly to the API and embed them in another data structure, you
have to be more explicit. Let's go ahead and tell it to wait on
those results::

    [10000..10100] \ (n)->API.entity id:n \ wait

The ``wait`` command will scan through the data it gets from the
pipeline and replace all of the promises with the fulfillments of
those promises as they come in. It also has an optional timeout
which will cause the wait to stop if it has been more than that
long since an update was received. The default timeout is 60
seconds, and you can change it by simply specifying a different
number as an argument to the wait command. This argument is a full
coffeescript value, so you can use variables and functions if you
need to for some reason.

As you wait for the entities to come down, notice that there is a
progress bar on top of the command line to let you know something
is happening in the background, and the fraction of finished to
total promises is displayed at the right end of the command line. 

When it's all said and done, you should have a list of 101 entities
in your text window.

Make a bar chart
----------------

Let's take those entities and see how they're distributed by
type. To do that, we'll fetch the entities, then pick out the type
field, group them by that field, and make a chart that has a bar
for each type and shows the number of instances of that
type. First, let's get the entities again and stash them so that we
don't have to wait for them to download at each step::

    [10000..10100] \ (n)->API.entity id:n \ wait \ store ents
   
The ``store`` command takes a variable name and stores the result of
the preceding command in the scope under that name. Now you can
access that list of entities using the name ``ents`` from anywhere in
future commands. First, let's strip out all of the data we don't
care about from them::

    ents \ (e)->e.type

Now you should see a list of the type fields from each entity. Next
we'll group them according to that field::

    ents \ (e)->e.type \ group (x)->x

This command uses the ``group`` command, which takes a function and
returns an object. The function should return a name for its input
that specifies what group it belongs in. In this case, all we have
are names, so we just tell it to return its input unchanged (that's
what the ``(x)->x`` means - a coffeescript identity function).

The output of the group command was an object with a key for each
group name, and the list of things in that group for the value. Now
we're going to replace the lists with their lengths, which will
give us a nice data structure to pass to the ``barchart``
visualization primitive::

    ents \ (e)->e.type \ group (x)->x \ (ls)->ls.length

This uses the map command to iterate over the keys of the object
returned by group and replace each value by its length. You should
now have an object with a few keys, each with a number as its
value. This is exactly the format we need for a bar chart, so let's
see what we get::

    ents \ (e)->e.type \ group (x)->x \ (ls)->ls.length \ barchart

You should now see a chart showing the relative frequencies of the
different entity types in your set. If your text area is covering
the chart, you can double click the top of it to auto-minimize. It
will remember the last setting for the height, so if you double
click it again it will go back to where it was.

Event Timing
------------

Next we'll use a dot chart to look at the timing of a set of alerts
coming in within an alert group. First, let's get the alerts::

    alertgroup: id:1512214,sub:'alert'

After this comes in you should have a list of alerts. There's a lot
of data we don't really care about there, so let's tell the server
to only send what's important::

    alertgroup: id:1512214,sub:'alert',columns:['id','when']

This filters the data coming in down to just the ``id`` and ``when``
columns, which suits our needs for this example. We can store that
data for future reference::

    alertgroup: id:1512214,sub:'alert',columns:['id','data'] \ store a151

We're going to make a dot chart with time on the horizontal axis
and item number on the vertical (vertical axis is just here to
separate things for visibility). We need to pull out the time value
for each and pair it with its position in the list::

    a151 \ (alert,pos)->[pos,alert.data._time]

The map function implicitly passes the index of the current element
to the handler function (or the key if it's an object). We just use
the object's list position to get a vertical coordinate for
it. Unfortunately, this timestamp is in human-readable format,
which makes it a pain to use. We can parse it using the Strings
function though::

    a151 \ (r)->r.data._time \
        pick Strings.pat.hms \
        (ls)->(map ls[1..],(s,i)->(60**(2-i))*(parseInt s)).reduce (a,b)->a+b 

This takes the alerts and uses the Strings predefined ``hms``
(hours:minutes:seconds) pattern to parse just the clock time from
the timestamp. The pattern returns the matched string along with
its captured substrings, which in this case gives us the hour,
minute, and second. The function mapped over it just converts this
into a number of seconds since midnight. Coffeescript has a ``**``
operator for exponentiation, if you're trying to parse out how that
function works. Now we have a list of timestamps, so let's convert
it to a list of coordinate pairs that ``dotchart`` can use::

    a151 \ (r)->r.data._time \
        pick Strings.pat.hms \
        (ls)->(map ls[1..],(s,i)->(60**(2-i))*(parseInt s)).reduce (a,b)->a+b \
        (n,i)->[n,i] \
        dotchart

Whoops, looks like the timing data is all over the map! We need to
sort our timestamps in ascending order since they didn't come that
way from the server::

    a151 \ (r)->r.data._time \
        pick Strings.pat.hms \
        (ls)->(map ls[1..],(s,i)->(60**(2-i))*(parseInt s)).reduce (a,b)->a+b \
        sort \
        (n,i)->[n,i] \
        dotchart

``sort`` does just what you'd think. You can optionally pass it a
comparison function, which should return -1, 0, or 1 depending on
whether the first argument is less, equal, or greater than the
second. Note that javascript has some very weird ideas about
ordering, so if you want to get the expected sort order for normal
data (numbers, strings, etc.) REVL provides a sort function in the
Utils module called Utils.smartcmp. This basically says numbers go
in numeric order and strings go in alphabetic order. In javascript
by default, numbers go in alphabetic order (!). Running this
command we can now see a nice progression of alerts that ended up
in this alert group.

Other interesting command examples
----------------------------------

Here are some other commands you might want to play with to get a
feel for the system. All of the basic commands have documentation
with examples, so if you need to look something up to see how it
works start with the help system.

* Entity Frequencies over time

  Query 1000 entries, pull the entities for each of them, group them by
  type, and create a barchart to show the relative frequency of each
  type of entity::

    $ [10000...11000] \
        (n)->API.entry {id:n,sub:'entity'} \ 
        wait \
        (r)->Struct.tolist (Struct.map r,(v)->v.type) \
        flatten \
        group (ls)->ls[1] \
        (ls)->ls.length \
        barchart

* Examine event timing over long periods

Query 500 events, extract the creation timestamp, sort them in
ascending order, rebase the time to show time delta in minutes from
start of record, and create a dot chart to show the timing of
clusters of events and highlight gaps in the record::

    $ event limit:500 \
        (e)->e.created \
        sort \
        into (ls)->map ls,(n)->(n-ls[0])/60000.0 \
        (n,i)->[n,i] \
        dotchart

* Look at sequence of alerts in alertgroup::

    $ alertgroup id:1512214,limit:100,sub:'alert' \
        (r)->r.data._time \
        pick Strings.pat.hms \
        (ls)->(map ls[1..],(s,i)->(60**(2-i))*(parseInt s)).reduce (a,b)->a+b \
        sort \
        (n,i)->[n,i] \
        dotchart

* Network connections between emails mentioned together in an alert for an alert group

Get the alerts for alertgroup 1512214, concatenate all of the
strings in the data field of each, pick out all of the email
addresses in the resulting strings, generate pairs from all emails
that were in the same alert, and make a force-directed graph from
the resulting structure.::

    $ alertgroup id:1512214,limit:100,sub:'alert' \
        (r)->(squash (Struct.tolist r.data)).join ' ' \
        (s)->Strings.pick Strings.pat.email, s \
        (ls)->ls.map (m)->m[0] \
        (ls)->cmb ls,2 \
        flatten \
        forcegraph

* Association matrix of emails from one alertgroup

This is a very heavy computation, but it eventually finishes. Need
to look into ways to optimize this to make it more convenient, but
the filling out of the table really explodes the size of the data
set.::

    $ alertgroup id:1512214,limit:100,sub:'alert' \
        (r)->(squash (Struct.tolist r.data)).join ' '\
        (s)->Strings.pick Strings.pat.email, s \
        (ls)->ls.map (m)->m[0] \
        (ls)->cmb ls,2 \
        flatten \
        nest (n)->n \
        (row)->Struct.map row,(col)->col.$.length \
        tabulate {} \
        grid \
        eachpoly (p)->if p.input == {} then p.color='#000' else p.color=Utils.heatColor p.input,10 \
        draw
 
* Draw a treemap from an Nspace::

    $  [1..100] \
        foldl new Nspace (s,pt) -> s.insert pt,[['x',Math.random()],['y',Math.random()]]; s  \
        into (s)->s.subdivide() \
        into (sp)->sp.leaves() \
        (l)->l.bounds \
        (bnd)-> zip bnd \
        (pts)->[[pts[0][0],pts[0][1]],[pts[0][0],pts[1][1]],[pts[1][0],pts[1][1]],[pts[1][0],pts[0][1]]] \
        (pts)->(polygon pts).scale 200 \
        into (polys)->{polygons: polys} \
        draw

* Network showing relationship between events and entities

Query an event, find all the entities associated with it, then find
all the events associated with those entities. Make links
accordingly, then display as a force-directed graph. Mousing over
the network nodes will display the entity name or event id number
depending on what kind of node it is.::

    $ event id:10982,sub:'entity' \
        (e,k)->[{id:e.id,name:k},10982]  \
        tolist \
        (ls)->ls[1] \
        filter (ls)->ls[0].id not in [4802,97248,19,533065,97249] \
        (ls)-> [[[ls[0].name,ls[1]]],(API.entity sub:'event',id:ls[0].id).map (e)->([ev.id,ls[0].name]) for ev in e] \
        wait \
        flatten \
        flatten \
        forcegraph

* Barchart of event count for each entity

  Fetch the entities associated with an event, then fetch all of the
  events for each entity and make a barchart that shows how many
  events are associated to each entity.::

    $ event id:10982,sub:'entity' \
        (ent)->(API.entity id:ent.id,sub:'event',columns:['id']).map (ls)->ls.length \
        wait \
        filter (n)->n>20 \
        barchart

