Authentication/Authorization
============================


Authentication
^^^^^^^^^^^^^^

SCOT Authentication system has been revamped to integrate easier with existing
authentication systems you may already be using.  We'll describe the provided
methods below and discuss how you can build your own.

RemoteUser
~~~~~~~~~~

This method is designed to work with existing single sign on systems and other
authentication methods that can be integrated into the Apache Webserver.  This
method relies completely on Apache telling the SCOT application server who is
trying to access SCOT.  Examples include configuring Apache to authenticate 
via Kerberos or LDAP. 

How this works is that the Apache webserver modules actually perform the 
authentication and set the REMOTE_USER environment variable.  This is passed
to the SCOT application server and SCOT accepts this as the truth.

Advantages:  Integration with existing account processes.
Disadvantage:  Basic Auth.  Very difficult to "log out" of SCOT. (must delete
scot cookies and kill all browser processes)

Ldap
~~~~

This method reduces the Apache webserver to "just" a Reverse Proxy to the 
SCOT application server.  SCOT then will present a form base login to the 
unauthenticated user.  SCOT will authenticate against Ldap as that user
and assuming success, will consider the user authenticated.  

Advantages:  Integration with existing directory.
Disadvantage: Configuration of LDAP can be tricky.


Local
~~~~~

Local is like the Ldap method above, except user identity is checked against
the user collection in the SCOT database.  

Advantages: Simple.  No need to work with others to control access.
Disadvantages: More work for you.  

Roll Your Own
~~~~~~~~~~~~~

This is left as an excersise for the reader (don't you hate that...).
See lib/Scot/Controller/Auth/ for examples.

Changing Authentication Methods
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To change authentication method, you will need to edit the /opt/scot/etc/scot_env.cfg file.  Look for the "authtype" item and change the value.  For example:

    authtype => 'Remoteuser',

After saving the changes, you will need to restart the scot server with the
command:

    # service scot restart


Authorization
^^^^^^^^^^^^^

Authorization is based on a group membership model.  All "Permittable" objects
(Alert{groups}, Events, Intel, Incidents, Entries, etc.) contain a list of groups
that are allowed to view or modify those records.  SCOT will only display 
records that you are Authorized to see and will only allow modification to those
in the proper group.

Group membership looks can either be to an LDAP server or to a SCOT controlled
group collection.  Either way, best practice is to include a common string in
every group that has do with SCOT access control.  For example, you could prefix
every group with scot- or ir-.  Just be consistent, it will make your life 
easier, I promise.



