Threat Intel in SCOT
====================

Intel Grid
^^^^^^^^^^^^^^^^^^^^^^^^^

Here we will go more indepth about the threat intel section of SCOT and how you can leverage its capabilities to the fullest.

We’ll start by clicking on the “Intel” button in the top menu which will take us to intel grid. You’ll see a document already exists (“Intro to SCOT’s Threat Intel section”), as well as a “Create Intel” button in the top left hand corner.

.. figure:: _static/images/intelgrid.png
   :width: 100 %
   :alt: Image of Intel Grid Here

If you want to view an existing piece of intel, just click on the row for the document of interest. The document will load in the lower pane of the screen. Note: Double clicking a row automatically expands the document hiding the grid.

If you want to add a new piece of intel, just click the “Create Intel” button and a new empty document will be added. Read the “Intel Details” section next for information about how to add information to this new Intel Object

Intel Details
^^^^^^^^^^^^^

So, we’ve created a new Intel object, but how do we add our information to it?

First, let's set a subject so everyone else knows what this intel object is about. We do this by clicking in the subject box in the Header of the Intel Details (see image below) and modifying the text like we would any other textbox.  Changes to the subject box are saved as you type.

.. image:: _static/images/intel_details_header.png
   :width: 100 %

You can see we've added a Tag of 'APT' to improve searching later on.  You can add a tag by clicking on the |add| icon or remove one by clicking on the |x|.

Now that we've set the metadata for our intel object, let's go about actually adding the information and IOCs.

Go ahead and click the "Add Entry" button at the right of the header.  A blank textarea with a green background will appear in the details section (this indicates you are in edit mode).  Additionally, a rich text editor toolbar will appear for advanced formatting.

.. figure:: _static/images/intel_details_add_entry.png
   :width: 100 %

Go ahead and either paste in the report from email or a website, or type it in manually. Click “Save” and this entry will now be added to this intel object. Here is what it looks like after we pasted in our indicators.

.. figure:: _static/images/intel_details_one_entry.png
   :width: 100 %

WOAH! What's with all that |flair|?

* SCOT Automatically extracts IOCs (Domains, IPs, Hashes, Emails, etc.) and highlights them for you.

Why do some of the highlighted parts have numbers like |count| after them?

* The number after a highlighted IOC tells you how many times previously SCOT has seen this indicator.  For example, we've seen *rnil.am* three times before, and if we want more information, we can click on the Indicator.

Ok, but what about that internet explorer icon |ie| on kavkazcentr.info?

* SCOT Integrates into your blocklist to automatically tell you which domains are blocked without you having to look it up. If we had an IP Address, we’d see a small flag next to it indicating the country in which the IP Address is registered.

We refer to the highlighting of IOCs and display of basic information as "Flair".

.. |x| image:: _static/images/remove_x.png

.. |add| image:: _static/images/add.png

.. |ie| image:: _static/images/blocked.png

.. |count| image:: _static/images/referenceCount.png

.. |us| image:: _static/images/us.png

.. |flair| raw:: html

   <span style="background-color: rgba(255,245,168, 0.5); border: 1px dotted green; border-radius: 6px; padding: 1px">yellow hilighting</span>


