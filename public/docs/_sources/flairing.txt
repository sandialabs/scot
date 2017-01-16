The "Flairing" Process
======================

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

