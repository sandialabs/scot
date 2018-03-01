Recieving Alerts
================

There are two primary ways to recieve alerts in SCOT, via IMAP or by posting
to the JSON API.  Here's how to set things up so that you can begin viewing
alerts in SCOT.

IMAP
----

One common feature of most security detection suites is the ability to send
an e-mail when certain conditions are met.  We can utilize this feature 
to import these e-mails into SCOT.

First you will need an IMAP server configured to receive e-mails from 
your detection devices.  You can utilize an existing IMAP (even an 
exchange server configured to talk IMAP) if you wish.  Set up an account,
like 'scot-alerts', on the IMAP server and configure devices to send 
e-mails to that account.  

Next you will need to configure the e-mail alert ingester, 
/opt/scot/bin/alert.pl, by creating or modifying the the file 
/opt/scot/etc/mail.app.cfg.  

The sample mail.app.cfg looks like:


.. literalinclude:: ../../etc/mail.app.cfg 
   :linenos:

One advantage of using this method is that the IMAP server acts as a 
store and forward buffer for you alerts.  This means that alerts from 
you detectors can buffer up while you upgrade your SCOT system.  It also
allows for reprocessing of old alert e-mails.

REST API
---------

This method allow you to create your own ways to pump alerts into SCOT.
Using this method you would POST a block of JSON to SCOT.  You can even
use curl to create an adhoc alert.

.. literalinclude:: ./sample_ag_post.sh
   :linenos:

More details on the REST api are available at `SCOT API documentation.
</api/index.html>`_
