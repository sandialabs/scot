User Guide
==========

SCOT is divided into several main sections.  Alerts flow into SCOT and are processed in the
Alert tab.  Some subject of those Alerts will be promoted into Events, where the team 
records the results of their investigations.  A subset of those Events will be important
enough to be promoted into Incidents.  Simultaneously, new Intel reports will be created
and addes to SCOT.  The sections below describe how to use each section.

Views
-----

List View
^^^^^^^^^

A grid that can be filtered that display many things (alertgroups, events, etc.)  

Detail View
^^^^^^^^^^^

The section of the page that displays details about the thing selected in the the List view.

Alert
-----

To access the Alert Grid, click on the “Alert” button in the Navigation Bar at the top. The grid will appear in which we see a list of alerts that have come in and need to be triaged. Each row represents a group of alerts that came in together and are possibly related. Let’s go over what each of the columns in the grid means.

:Status:  The status can be either *open* (no action taken), *closed* (no action needed), or *promoted* (more analysis needed).  All alertgroups come into SCOT as "open".
:Sources:  The "sources" column identifies the systems/organizations/processes that are responsible for creating the alert.
:Subject:  The subject is a quick description of the alertgroup.  If the alert came in through email, this is the email subject.
:Tags: Tags are seen as a catchall and are useful in subsequent searches for alerts with a specific set of tags.
:Views: You can also filter by the number of times a particular alert has been viewed to know if anyone else on your team has looked at it.

.. figure:: _static/alertfilters.png
   :width: 100 %
   :alt: Filters in alert grid

Each column contains a textbox to filter the grid results.  Just enter in a filter and press 'Enter' on your keyboard to activate the filter.  You can also click on a column above the filter textbox to sort by that column.  We can see the default sort order is by 'created' which is indicated by the chevron next to the column name.

A summary of alert status within an alertgroup can be quickly determined by glancing at the status column.  The legend below explains the shapes/colors used.

.. figure:: _static/ag_status.gif
   :width: 100%
   :alt: Alertgroup status

Alert Details
-------------

Let's look at the contents of an alert by clicking on one of the rows in the Alert Grid.  Note: 

.. figure:: _static/alert_details.png
   :width: 100 %
   :alt: Screen capture of alert details

Inside the Details view, we see the header (black background, white text).  The header allows us to edit basic metadata about the alert such as the subject, close/open it, add/remove tags and sources.

To change the subject, click in the black subject box and edit like you would any other textbox; changes are saved in real time.  To change the status of an alert, click on the button titled "open".  To add a tag, click on the |add| button and start typing.  To remove a tag, click the |x| associated with it.

Now let's look at the context sensitive command bar located directly below the header.

.. figure:: _static/AlertMenuContextUnselected.png
   :alt: Alert Context Menu with no selected alerts

:Toggle Flair:  Toggle the display of Flair.
:Reparse Flair: Mark the Alertgroup for re-parsing by the Flair engine
:Guide:         Display the Guide for this Alertgroup type.
:View Source:   View the raw unparsed versions of the Alertgroup
:View Entities: View the list of discovered Entities in this Alertgroup
:Viewed by History: See who viewed this alertgroup.
:Alertgroup History: See the history of actions taken on this Alertgroup

After clicking on one or more Alerts in the detail view, the 
alertgroup context menu changes to

.. figure:: _static/AlertMenuContextSelected.png
   :alt: Alert Context Menu with alert selected

:Open Selected: Change status of selected alerts to "open"
:Closed Selected: Change status of selected alerts to "closed"
:Promote Selected: Change status of the selected alerts to "promoted"
:Add Selected to Existing Event: Add the selected alerts to an existing event.  You will need to know the event number.
:Add Entry: Add an Entry to the selected alerts
:Upload File: Upload a file and associate it with the selected alerts
:Export to CSV: Export the detail view into a CSV file and download it to the desktop.

Let's look at the actual alerts in this alertgroup now.  Each row in the table represents an alert, which may or may not be related to the other alerts. You can select one or more rows by clicking on them and utilizing the Shift and Ctrl keys as you would when selecting files in Windows Explorer.  Selected row(s) are highlighted in green.

.. image:: _static/alert_rows.png
   :width: 100 %

For each alert, we want to answer the following:

* Is this a false positive?
* Do we have enough information to continue?
* Should we investigate further, or is this known to be malicious?

If this is a **false positive**, we can go ahead and close the alert by first selecting it, then choosing the "Close Selected" button from the context sensitive menu above.  The status for this alert will change to closed and this status change will appear instantly on the screen of all other analysts.

If there is not **enough information** to continue, but there is some information about this alert that could be helpful to another analyst, select the alert and click "Add Note".  In the new textarea that pops up, type your note (full HTML support) and click "Save".

If we need to **investigate further**, select the row(s) in question and click 'Promote Selected'.  This will create a new Event where you can document your findings and collaborate with other analysts on your team.  This event is linked back to the original alert, so no data is lost.

.. |x| image:: _static/remove_x.png

.. |add| image:: _static/add.png

Events
------

This is where the fun begins!  Promotion to an Event, is a signal to the team that the promoting
analyst thinks that there is something in this alert that merits the attention of the team.  
During this phase, the team is investigating the alert, dropping their results into Entries,
creating a summary, asking each other for help via Tasks, and tagging the results.

Event Grid View 
^^^^^^^^^^^^^^^^^

The Event grid allows you to view sets of Events and to filter those sets in various ways.

.. figure:: _static/EventListView.png
   :width: 100 %
   :alt: Sample Event List View


Event Detail View
^^^^^^^^^^^^^^^^^

.. figure:: _static/EventDetailView.png
   :width: 100 %
   :alt: Sample Event Detail View

:Event Id:  Each Event has a unique integer id assigned to it.
:Subject:   The team can give each event a subject.  By default, it will be the same as the alertgroup.
:Status:    The event can be "open", "closed", or "promoted."  Many events can remain "open."  Some people get hung up on an event being open for months, but it really only means that the team thinks that there may be more to come on this event in the future.  "Closed" should be reserved for this is no longer actively being worked.  Promoted gets assigned if the Event becomes an Incident.  The status is easily changed using the pull down.
:Owner:   Every Event has an owner. 
:Updated:  This the time of the last update of this event.
:Promoted From:  Links back to the alerts that originated this Event.
:Tags: Add, Delete, or Edit the set of tags applied to this event.
:Source:  The Source of this Event.  Analysts can add to this.
:Add Entry: This is how the analyst creates an new entry box to enter information about the Event.
:Upload file:  Upload a file and associate that file with this event.
:Toggle Flair: Turn Flair on or off
:Viewed by History: See who has been viewing the event
:Event History:  See the changes that have happend to the event
:Permissions:   View and change the groups that have read and write access to this event
:View Entities: See all discovered Entities
:Promote to Incident: promote the event up the food chain
:Delete Event: Delete this event.

The first boxes after the command buttons are known as Entries.  There are several 
types of entry box.  The first entries to appear will be Summary entries, if they exists.
Summary entries are highlighted in light yellow.  In the example above, a summary entry
has not yet been created.  

Alert recap Entries usually appear next.  These entries contain a copy of the alert data
so the analysts does not have to switch back to alert view to see the details.

Other entries follow and contain data input by the analyst and, in the future, from automated
processes.  Entries with a red title bar are Tasks that have yet to be marked as completed.  
Green title bars denote completed tasks.

Incident
--------

Incidents are groupings of Events.  One way to use Incidents is to track the Events that rise
in importance that they need to be reported to another organization or to higher management.
Incidents track metadata such as type of incident, category, sensitivity, dates when the 
incident occurred, was discovered, was reported, and when closed.  Also the Incident can be
linked to external reporting ids.

Intel
-----

The Intel collection is for tracking cyber security intel reports from public or private
sources.  Once input, the Flair engine will detect and cross correlate all Entities found
with the Intel record.  This can be very powerful and easy way to find threat actors withing
you existing SCOT data as well as flagging it in new incoming alerts.

.. figure:: _static/intel_details.png
   :width: 100 %
   :alt: Sample Intel Detail View

In the example above, we see that an analyst received a heads up from a friend at the XYZ corp.
The analyst created the intel record, and SCOT flaired the screensaver name and the hash of
that file.  Now the analyst can immediately see that the kittens.scr has been seen in the SCOT
data one other time and can click on the kittens.scr to see where and what was done about it.

Guide
-----

Guides are instruction manuals, built by the team over time, on how to handle an Alert type.
This can greatly speed the training of new analysts and provide a forum for the team to 
share their techniques for investigating an alert type.

Task
-----

Tasks are used mostly in Events to note a unit of work that still needs to be performed for example, "Pull pcap for 8.8.8.8 from 8am - 2pm".  Some people use these as reminders for tasks they have to do later in an investigation, and some use them to request help from other members on their team.  

This feature has proven very helpful when working on large events by coordinating what work still needs to be done, and those who are working on it.  The user creates an entry and by clicking the dropdown selects "Make Task".  This task now shows up on the task list, and anyone from the team can take ownership of the task.  This way an analyst that just came back from lunch, or just arrived at work can jump right in.

When a task is created, the creator owns it.
The only way to transfer ownership of a task is for another team member to "take ownership."
This prevents tasks being pushed onto someone who may be on vacation.  If you want to help,
take the task.  If someone whats it back, they can take ownership again.

Signature
---------

Signatures are used to integrate the version control of signatures within 3rd party mitigation tools (firewalls, IDS, etc.) while being managed by SCOT as a central repository. Signature's have the same list view as other "things" within SCOT, but they have a slightly modified detail view. 

The detail view of signatures contain metadata editing, where you can modify a description, signature type (yara, ids, firewall, etc.), production and quality signature body versions, signature group that the signature belongs in, and signature options (written in JSON format). The final new item within the detail view is the Signature body editor. This editor should be used to add in the signature's that will be used in the 3rd party tool. The output of the body is converted to a string format, which can then be ingested by the other tool.

Below these new sections, the entries that are found in other "things" still exist.

See the signature page for more information.

Tags
----

Tags are way to annotate AlertGroups, Events, Intel, Incidents, and Entities within SCOT.
Say an particular Alert was a false positive.  Tagging that alert as "false_positive" will
give the team to track all false positive alerts and their occurrence over time.  This can
be very helpful in debugging or improving detectors.

Tags are space delimited.  In other words tags can not contain a space.  You can apply many 
tags to a taggable object.  With some creativity you can create grouping of tags by placing
a seperator in the string like: "ids:false_positive" to track false positives in the ids system.

Flair
-----

What the heck is Flair?  
^^^^^^^^^^^^^^^^^^^^^^^

The inspiration for the term comes from the classic film "Office Space" (see https://youtu.be/_ChQK8j6so8).  We wanted to add pieces of "flair" to indicators of compromise (Entities) to give instant information to analysts.  Currently, flair items include a growing list including:

- number of times the Entity appears in SCOT
- country flag for Geo location of IP address
- the existence of notes about the Entity

The Process
^^^^^^^^^^^

Upon Alert or Entry input to SCOT, a message is emitted on the SCOT activity queue.  The Flair process, which eagerly listens to this queue, retrieves the Alert or Entry via the REST API and begins processing the HTML.  

If we are processing an Entry, we first scan for <IMG> tags.  IMG tags may be links to external websites, internal websites, or Base64 encoded data.  Links to external sites may open you up to data leakage (think web bugs), internal sites may require anoying re-authentication, and storing Base64 images within Entries can cause slow downs in storing and indexing those images within SCOT.  So let's cache those images locally on the SCOT server. 

Assuming that Flairing is running on the SCOT server, external and internal images are pulled down to the server.  Base64 images are saved as a file.  The HTML of the Entry is modified to point to the new location of the cached file.  If flairing is running on a seperate system, it will upload the cache image file to SCOT via the REST API and issue an update to the Entry's HTML.

We don't usually encounter IMG tags in Alerts, so we skip scanning for IMG tags.  (If you do, place a feature request for us to handle it!)  

Next, the Flairing process parses the HTML in the Alert or Entry begins looking for flairable items.  The following items are detectable:

- IP addresses
- E-mail addresses
- Domain Names
- File names with common extensions
- Hexidecimal Hash representations like MD5, SHA1, and SHA256
- Latitude/Longitude coordinates

These Entities are extracted via Regualar Expressions.  If you develop other interesting extractions, please submit a Pull request to have them included in Scot::Util::EntityExtractor.  

Extracted Entities are stored within the SCOT database and Links are created to the Alert/Alertgroup or Entry and parent Alertgroup, Intel, Event, or Incident.  The source HTML is also modified to wrap the Entity with a <span> tag of class "entity."  Addition classes may be applied to the Entity based on the type of the Entity.  

User Defined Entity
^^^^^^^^^^^^^^^^^^^

You can highlight text within an Entry and a new button will appear that will
allow you to "create user defined entity."  You will be asked to describe the
type of the entity.  Once you click on create, SCOT will then search through
all alerts and entries for that string and flair them.  All future appearances
of that string will also be flaired as an entity of the type you created.

For example, let's pretend you just created an entry that says::
   
    The fuzzy foobar group's fingerprints are all over this.

You want to link "fuzzy foobar" as a threat actor group and be able to find
other references to this group within SCOT.  Highlight the text "fuzzy foobar"
click "create entity" and enter "threat-actor-group" as the type. (spaces are
autocoverted to dashes '-').  Now SCOT will add "fuzzy foobar" to the list of
flairable entities and well as "reflairing" instances in previous entries.

Entities
---------

SCOT parses the alert data and entries for various entities.  Entities are commonly refred to as IOC's (indicators of compromise) but are only limited by the ability to parse and extract strings within the alert and entry data.  

Once identified, SCOT, stores metadata about these entities that allows the SCOT UI to "flair" them with highlighting, badges, and other useful visual indicators that help analysts to rapidly identify the impact of the entity.

Entity Types
^^^^^^^^^^^^

SCOT can automatically detect and extract the following Entities:

.. glossary::

    Domain Names
        SCOT extracts domain names in form of host.sub.domain.tld, where tld is 2 to 6 characters in length.  Secondary validation against Mozilla's TLD database (effective_tld_names.dat)

    File Names
        Common filename extensions such as exe, pdf, and so on are detected by SCOT.

    Hashes
        SCOT can extract MD5, SHA1, and SHA256 hashes from input data.

    IP Addresses
        SCOT will extract IP addresses.  IP version 4 address will have type ipaddr, and IP version 6 addresses will have type "ipv6".

    Email Addresses
        E-mail addresses, both email username and the domain, are extracted and watched.

    Latitude/Longitude
        In the form of -120.093 +100.234

    CVE
        SCOT will detect CVE names in the form of "CVE-YYYY-XXXX"

    CIDR
        SCOT will detect CIDR blocks in the form of X.Y.Z.0/A, where A is 0  through 32.  As an added benefit, SCOT will also link ip address entities that are
        in that CIDR block to this entity as well.





        

Building Additional Entity Types
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The primary tool for entity extraction is the Perl module Scot::Extractor::Regex
Additional regular expression may be added to this module to extract additional entities.  

Another way to add additional Regexes is to add them to your scot.cfg.pl.  Add a key "entity_regexes" to the cfg file.  This array of items will be added to the Regex module at server start time.  

The format of the regex item is::

    {
        type    => "name_of_the_entity",
        regex   => qr{ regex_here },
        order   => number,    # lower numbers get precidence over higher
    }



Permissions
-----------

The SCOT security model is a group based access control.  Top level "things"
like alertgroups, events, incidents, guides and intel have a attribute called 
"groups."  The groups attribute an object of the form::

    group: {
        read: [ 'group1', 'group2' ],
        modify: [ 'group1' ]
    }

As you would imagine the read attribute lists the groups that are allowed
to read this "thing." Similarly, the modify field lists the groups that can
modify the "thing."  When an Entry is created for this "thing," unless 
expressly set, the permissions of the entry will default to this set of 
permissions.

Somewhat surprisingly, a subset of data about a thing, namely the details
in the "list view" are viewable by everyone regardless of group membership.
The primary reason for this is to allow teammates to see that an alert or
an event exists.  If that teammate is not in the proper group membership,
SCOT will inform them, and the teammate can inquire with his team 
administrator about joining that group.   We feel that the small risk of
data "leakage" is outweighed by the benefit of the team being able to discover
events that they may be able to contribute to.  

Default Groups and Owners
^^^^^^^^^^^^^^^^^^^^^^^^^

Default groups are set in the /opt/scot/etc/scot_env.cfg file.  The
default owner is also set in this file.  

Admin Group
^^^^^^^^^^^

The admin group name is also defined in the /opt/scot/etc/scot_env.cfg file.
Members of this group have "root" powers and can change ownerships, and
read and modify group settings.

Note about Group Names
^^^^^^^^^^^^^^^^^^^^^^

If you are using LDAP to manage group membership, and your team members 
have large sets of groups they belong to, you can run into a limit in the 
number of characters returned from LDAP.  This sometimes truncates the 
grouplist in such a way that the SCOT group may not be returned.

To help avoid this, SCOT filters the LDAP query looking for a common string
in all SCOT groups.  By default this is "wg-scot" but can be changed in
the /opt/scot/etc/ldap.cfg file.  The line::

    filter  => '(| (cn=wg-scot*))'

can be changed to whatever naming convention you decide upon.

HotKeys
-------

The following hotkeys are supported::

    f: Toggle full screen mode when a detail section is open
    t: Toggle flair on/off
    o: This will open all alerts within the alertgroup when in the alertgroup list view as your focus. 
    c: This will close all alerts within the alertgroup when in the alertgroup list view as your focus. 
    j: This will select one row down within the list view.
    k: This will select one row up within the list view.
    esc: This will close the entity pop-up window. 

Posting a global notificaton:
-----------------------------

A global notification can be posted to all users by navigating to::
    
    https://<scot instance>/#/wall

Note that only raw text will be displayed.
