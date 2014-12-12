.. _scratchpad:

Scratch Pad
===============================

The ScratchPad allows you to quickly check a large number of indicators against SCOT.

You can access the scratchpad by clicking on the |scratchpad| icon in the top right hand corner of SCOT.

Enter text / html into the light blue square and as you type, IOCs will be extracted and shown in the pink square.  SCOT will then be queried for those IOCs, and display its results in the yellow square.

.. image:: _static/images/scratchpad.png

In the yellow square, we first see the list of unique IOCs (entities) extracted and the amount of times they have been seen throughout SCOT.  This gives you a quick way to determine which of the IOCs have previously been identified.  

Below the unique entities table, we see a list of the locations throughout SCOT where these IOCs have been found. This provides a quick look at which alerts / events / intel are matching and indicates how they match in order to assist in further investigations.

This data is not automatically saved, a feature that prevents clutter in the events or intel sections of SCOT simply due to the testing of large IOC lists.

.. |scratchpad| image:: _static/images/notebook.png
   :width: 20px
