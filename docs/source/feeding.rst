SCOT Feeding
============

or How to get alerts into SCOT.

SCOT is designed to receive data from detection systems in two ways.

Email Ingest
------------

Many detection systems have the ability to generate email alerts.  For these systems, you should configure
those alerts to go to an email inbox that SCOT will have permission to access, e.g. scot-alerts@yourdomain.com. 
The Scot alert.pl program upon start will query that mailbox for messages.  Configuration of the alert.pl
program is handled in the /opt/scot/etc/alert.cfg.pl file.

Email ingest has many advantages, such as a flexible and resilient method of message delivery.  To use this
method, though, you must create a Parser for the type of Email message.  SCOT comes with sample parsers for 
Fireeye, Microsoft Forefront, Sourcefire, and Splunk emails.  These parsers, located in /opt/scot/lib/Scot/Parser
should provide a template to create your own parsers for the email from your detection system.  

The following section will show how the Scot::Parser::Splunk (/opt/scot/lib/Scot/Parser/Splunk.pm) 
module parses an HTML formated email.

HTML Email
^^^^^^^^^^

When creating a Parser module, you must first implement a "will_parse" function, that will return true
if your parser can parse the e-mail message.   Looking at Splunk.pm's will_parse function, we see the following::

    if ( $subject =~ /splunk alert/i ) {
        return 1;
    }

This means that if the subject of the email contains the case insensitve phrase "splunk alert", tell the alert
ingester that this is the parsing module to use to parse this email.

Another way to test would be to check the address of the email sender like this::

    my $from = $href->{from};
    if ( $from =~ /splunk\@yourdomain.com/i ) {
        return 1;
    }

Remember, the will_parse should return "false" (undef in Perl) if this parser can not parse the email.

The next function that must be implemented is the "parse_message"  function.  It is passed a hash reference
that contains the email's subject, message_id, plain text of email, and html version of email (if it exists).
At this point you have to refer to sample parsers provided on ideas how to parse your message.  If you get
stuck, please feel free to ask for help on our github page.

The result of the parsing should be a hash that looks like the following::

    %json = (
        data    => [
            { column1 => dataval11, column2 => dataval12, ... },
            { column1 => dataval21, column2 => dataval22, ... },
            ...
        ],
        columns => [ column1, column2 ... ],
    );

Note:  the hash may contain other keys besides data and columns depending on that data you want to extract 
from the email.


REST interface
--------------

OK, you've looked at the parsers, and for whatever reason you decide that creating your own is not the way
you wish to go.  In that case, the REST API is the way for you to go.  Essentially, you will need a username and
password, or an apikey from SCOT.  Then you will have to configure your detector to POST to SCOT via the API.
Alternatively, you could write your own wrapper to do the REST calls.

Here's a sample curl command to insert an alertgroup::

    curl -H "Authorization: apikey $SCOT_KEY" -H "Content-Type: application/json" -X POST -d '{
                "source": [ "email_examinr" ],
                "subject": "External HREF in Email",
                "tag": [ "email href" ],
                "groups": {
                    "read": [ "wg-scot-ir" ],
                    "modify": [ "wg-scot-ir" ],
                },
                "columns": [ "MAIL_FROM", "MAIL_TO", "HREFS", "SUBJECT" ],
                "data": [
                    {
                        "MAIL_FROM": "amlegit@partner.net",
                        "MAIL_TO": "br549@watermellon.com",
                        "HREFS": "http://spmiller.org/news/please_read.html",
                        "SUBJECT": "Groundbreaking research!"
                    },
                    {
                        "MAIL_FROM": "scbrb@aa.edu",
                        "MAIL_TO": "tbruner@watermellon.com",
                        "HREFS": "https://www.aa.edu/athletics/schedule",
                        "SUBJECT": "Schedule for next week"
                    },
                    {
                        "MAIL_FROM": "bubba@bbn.com"
                        "MAIL_TO": "fmilszx@watermellon.com",
                        "HREFS": "https://youtu.be/JAUoeqvedMo",
                        "SUBJECT": "Can not wait!"
                    }
                ],
        }' https://scot.yourdomain.com/scot/api/v2/alertgroup
