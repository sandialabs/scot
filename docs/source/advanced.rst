Advanced Topics
======================

Alert Parsing
-------------

REST or Email
^^^^^^^^^^^^^

SCOT can receive alerts via e-mail or by POST to the REST API.

Why E-mail
^^^^^^^^^^

Detections systems offer a wide variety of ways to notify something when a they detect something.  Most are optimized to work with their own console.  Some provide API's or other integrations.  Just about all offer the ability to send an email.

Getting your Hands Dirty
^^^^^^^^^^^^^^^^^^^^^^^^

Writing new parsers will require some programming work on your part.  Ruby, Python, et al. programmers should be able to extrapolate the concepts in the provided modules to develop there own alert input system utilizing the JSON web api.


Alert JSON 
^^^^^^^^^^

So this is what you need to POST to create an alertgroup with alerts.::

      {
            message_id  => '112233445566778899aabbccddeeff',
            subject     => 'test message 1',
            data        => [
                { foo   => 1,   bar => 2 },
                { foo   => 3,   bar => 4 },
            ],
            tag     => [qw(test testing)],
            source  => [qw(todd scot)],
            columns  => [qw(foo bar) ],
      }

Working with the Perl Parsers
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The perl alert parsing modules are located in the /opt/scot/lib/Scot/Parser directory.  They are descendents of the /opt/scot/lib/Scot/Parser.pm class.  The following parsers are included:
 
.. glossary::

    FireEye.pm
        This parser will parse e-mails from FireEye appliances.  This parser expects that the email is plain text with key value pairs seperated by colons (:).

    Forefront.pm
        This parser will parse Microsoft Forefront email messages.

    Sourcefire.pm
        Sourcefire email messages are handled by this parser.

    Splunk.pm
        Splunk can output messages in a variety of formats.  You will want to select HTML, as this parser relies on the HTML table layout of the these messages.  
    Generic.pm
        This parser will take the email, convert it to plain text and insert the results into an Alert as a single object. 


Entities, IOC, and Flair
========================

SCOT parses the alert data and entries for various entities.  Entities are commonly refred to as IOC's (indicators of compromise) but are only limited by the ability to parse and extract strings within the alert and entry data.  

Once identified, SCOT, stores metadata about these entities that allows the SCOT UI to "flair" them with highlighting, badges, and other useful visual indicators that help analysts to rapidly identify the impact of the entity.

Entity Types
^^^^^^^^^^^^

SCOT can automatically detect and extract the following Entities:

.. glossary::

    Domain Names
        SCOT extracts domain names in form of host.sub.domain.tld, where tld is 2 to 6 characters in lenght.  Secondary validation against Mozilla's TLD database (effective_tld_names.dat)

    File Names
        Common filename extensions such as exe, pdf, and so on are detected by SCOT.

    Hashes
        SCOT can extract MD5, SHA1, and SHA256 hashes from input data.

    IP Addresses
        SCOT currently only extracts IPv4 addresses.

    Email Addresses
        E-mail addresses, both email username and the domain, are extracted and watched.

Building Additional Entity Types
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The primary tool for entity extraction is the Perl module Scot::Util::EntityExtractor.
Additional regular expression may be added to this module to extract additional entities.  

We would also be happy to accept submissions from users on new ways to parse and extract entities.

