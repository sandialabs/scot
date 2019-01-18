Overview
================================

Cyber security incident response can be a dynamic and unpredictable process. What starts out as a simple alert may lead a team down a rabbit hole full of surprises. The Sandia Cyber Omni Tracker, SCOT, is a cyber security incident response (IR) management system designed by cyber security incident responders to provide a new approach for managing security alerts, including coordinating team efforts, capturing team knowledge, and analyzing data for deeper patterns. SCOT integrates with existing security applications to provide a consistent, easy to use interface that enhances analyst effectiveness.


Philosophy
----------

When Sandia’s IR team was looking for a system to capture its work product, they already had a great deal of experience with existing products. RT and its IR extensions, TRAC and Remedy were products that had been tested, along with several large SEIMS. For various reasons, none of these tools were adopted by the team. For some, the complexity of the tool prevented an already overloaded team from utilizing it. For others, there was a mismatch between what would be required of the team in order to use it and the reality of how the current IR process worked. From these frustrations and to fill the IR team’s need, SCOT was developed with these principles in mind:

  * SCOT should require minimal training to use and understand
  * SCOT should aim to always improve the effectiveness and efficiency of the IR analyst
  * SCOT should reward the IRT for it use.  


Why Use SCOT
------------

  * Designed to be easy to use, learn, and maintain.
  * Real-time updating keeps team in sync and their efforts coordinated.
  * Automated detection and correlation of common cyber security indicators such as IP addresses, domain names, file hashes and e-mail addresses.
  * Alert centralization from a wide range of security systems.
  * Extensible plugin infrastructure to allow additional automated processing.
  * Full Text searchable knowledge base that allows the entire team to easily discover and learn from past cyber security events.
  * Open Source.  Hack it up to meet your needs. (Please share!)

Our current users state:

  * SCOT just works and never slows me down.
  * I'm putting more and more of my investigation notes into SCOT.  It has paid of tremendously for me and helped me discover several non-obvious patterns.
  * Aside from my e-mail client, it's the one application that is always on my screen.
  * Give up SCOT?  I'd leave incident response first!

Terminology
-----------

Having a common vocabulary is very important to improve understanding.  So many terms are 
overloaded with meanings or have different connations to different teams.  The following 
sections define terms that SCOT use and the interpretation of those terms in SCOT's context.

IRT
^^^

Incident Response Team, a group of analysts that look for and respond to
security conditions.

Alertgroups
^^^^^^^^^^^

Many security applications have the ability to send data to other systems
when certain conditions are met.  These methods often vary widely.  There
is one commonality among most applications, however, and that is E^mail.

One of the ways SCOT can accept information from other systems is by setting
up an IMAP inbox that these systems can send E^mail to.  SCOT then periodically
checks that inbox, and ingests any new email messages it finds.  Creation of 
Alertgroups are possible via the REST API as well.

The E^mail messages may often contain several "rows" of data.  For example,
several IDS alerts could be bundled up into a single E^mail message.  This
grouping of alerts is called an "Alertgroup."  In other words, an Alertgroup
consists of one or more "Alerts" that was entered into SCOT at the same time.

Alerts
^^^^^^

An individual "row" from an "Alertgroup."  An alert can consist of any number
of key^value pairs.  An example alert could be the output of an IDS system
that shows a specific rule had triggered and the relevant details of that 
triggering.

The "Alert" is the starting point for the SCOT processing workflow.  Analysts
triage the incoming alerts and close or promote those alerts into "Events."

Events
^^^^^^

Typically, an experienced analysts should be able to deteremine if there is
something interesting about an alert in a few minutes time.  If there further
investigation is merited, the alert should be promoted to an "Event."  

The Event is where the majority of the IRT's work will be recorded.  Promotion
to an "Event" is a signal for the IRT that there might me something that needs
the team's attention.

Each analysts is capable of adding information into "Entries" and those notes
are instantly available to the rest of the team (assuming proper authorization).

The event lifecycle includes research and collection of data about the event
from the resources available to the team.  A summary may be created to allow
others coming late to the party to get up to speed.  Mitigation activities can
be documented as well.  Some Events are so serious in nature or group of Events
can be aggregated into an "Incident."  Finally, Events can be closed as a signal
that no further activity on that Event is expected.  If that expectation proves
false, the team can still add entries or even re^open the event.

Entry
^^^^^

An entry is a chunk of text or graphic data that is stored in SCOT.  Entries are
associated with Alertgroups/Alerts, Events, Incidents, Intel, and Entities.
The data entered into a Entry is scanned for "Entities" and "Flair" is applied
to entry to aid the analysts.  

Entries are "owned" by the creator of the entry, but may be edited by anyone
in the modify group.  Any entry can be "promoted" to Summary status and will
appear at the top of the detail page.  Entries may also be designated as a "Task."  

Task
^^^^

An Entry that has been marked as a task.  Tasks track "to^do" items and serve
as reminders to do things as well as requests for help from your team.  Tasks
can not be assigned to others, as a user must "take" ownership of a task.  This
prevents people from claiming not to see tasks in their "queue" and promotes
a proactive approach to team coordination.

Entity
^^^^^^

Entities are a growing list of string fragments that SCOT can detect within
entry data.  Examples include IP addresses, E^mail addresses, Domain names,
MD5 hashes, SHA1 hashes, SHA256 hashes, E^mail message id strings, and filenames
with common extensions.  Entities can be thought of as IOC's.  

Once detected in Entry data, Entities are cross referenced with the entirety
of SCOT's historical records.  Various data enrichment activities can also
take place based on the type of Entity.  Finally, the source Entry data is
rewritten to "Flair" or highlight these strings.

Flair
^^^^^

Flair is the highlighting and decoration of Entities.  First Entities are 
wrapped in a span that highligts them in yellow.  Next various icons are 
attached to the span that represent the number of times this entity has 
appeared in SCOT, flags for geoip data, if additional notes about the 
Entity are available, and others that you can implement. 

Intel
^^^^^

Often, IRTs receive information about threats, reports from other entities, and other general information that can be thought of as Intel.  Storing these items
within SCOT allows SCOT to detect entities, flair them, and cross reference these entities in existing and future Alerts and Entries.  

Guide
^^^^^

Guides are mini instruction manuals that help your analysts know how to respond
to incoming Alertgroups.  Guides are linked to the Alertgroup throught the Subject value of the Alertgroup.

Signature
^^^^^^^^^

Do you wish there was a place to store all your Yara, Snort, and other 
detection signatures?  We look no further.  Here you can store, discuss,
and revise your signatures and link them to your activities tracked in SCOT.
You can use the REST API to serve these signatures to your detection systems.





