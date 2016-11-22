SCOT Terminology
================

IRT
---

Incident Response Team, a group of analysts that look for and respond to
security conditions.

Alertgroups
-----------

Many security applications have the ability to send data to other systems
when certain conditions are met.  These methods often vary widely.  There
is one commonality among most applications, however, and that is E-mail.

One of the ways SCOT can accept information from other systems is by setting
up an IMAP inbox that these systems can send E-mail to.  SCOT then periodically
checks that inbox, and ingests any new email messages it finds.

The E-mail messages may often contain several "rows" of data.  For example,
several IDS alerts could be bundled up into a single E-mail message.  This
grouping of alerts is called an "Alertgroup."  In other words, an Alertgroup
consists of one or more "Alerts" that was entered into SCOT at the same time.

Alerts
------

An individual "row" from an "Alertgroup."  An alert can consist of any number
of key-value pairs.  An example alert could be the output of an IDS system
that shows a specific rule had triggered and the relevant details of that 
triggering.

The "Alert" is the starting point for the SCOT processing workflow.  Analysts
triage the incoming alerts and close or promote those alerts into "Events."

Events
------

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
false, the team can still add entries or even re-open the event.

Entry
-----

An entry is a chunk of text or graphic data that is stored in SCOT.  Entries are
associated with Alertgroups/Alerts, Events, Incidents, Intel, and Entities.
The data entered into a Entry is scanned for "Entities" and "Flair" is applied
to entry to aid the analysts.  

Entries are "owned" by the creator of the entry, but may be edited by anyone
in the modify group.  Any entry can be "promoted" to Summary status and will
appear at the top of the detail page.  Entries may also be designated as a "Task."  

Task
----

An Entry that has been marked as a task.  Tasks track "to-do" items and serve
as reminders to do things as well as requests for help from your team.  Tasks
can not be assigned to others, as a user must "take" ownership of a task.  This
prevents people from claiming not to see tasks in their "queue" and promotes
a proactive approach to team coordination.

Entity
------

Entities are a growing list of string fragments that SCOT can detect within
entry data.  Examples include IP addresses, E-mail addresses, Domain names,
MD5 hashes, SHA1 hashes, SHA256 hashes, E-mail message id strings, and filenames
with common extensions.  Entities can be thought of as IOC's.  

Once detected in Entry data, Entities are cross referenced with the entirety
of SCOT's historical records.  Various data enrichment activities can also
take place based on the type of Entity.  Finally, the source Entry data is
rewritten to "Flair" or highlight these strings.

Flair
-----

Flair is the highlighting and decoration of Entities.  First Entities are 
wrapped in a span that highligts them in yellow.  Next various icons are 
attached to the span that represent the number of times this entity has 
appeared in SCOT, flags for geoip data, if additional notes about the 
Entity are available, and others that you can implement. 

Intel
-----

Often, IRTs receive information about threats, reports from other entities, and other general information that can be thought of as Intel.  Storing these items
within SCOT allows SCOT to detect entities, flair them, and cross reference these entities in existing and future Alerts and Entries.  






