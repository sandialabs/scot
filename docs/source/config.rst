Initially Configuring SCOT
================================
Once you install SCOT, you are good to go, but you may want to add new users, schedule backups, and other things that good admins do. 

SSL Certs
^^^^^^^^^

SCOT will generate a "snake-oil" certificate upon install.  You will need to replace this as soon as possible with a real SSL certificate.  

LDAP/AD
^^^^^^^

My best advice is to buy your LDAP administrator lunch.  There are so
many ways to (mis)configure LDAP, that telling you how to do it is beyond
the scope of this manual.

I can help you with the what the fields in the scot configuration are 
looking for.

hostname
  use the fully qualified hostname for the LDAP/AD server, e.g. "ldap.foo.com"

dn
  The string is the distinguished name and can be provided by your LDAP admin.  typically, it looks like: "cn=something,ou=local confi, dc=edu"

password
  some LDAP/AD instance require a password

scheme
  typically "ldap".

group_search
    This is how scot gets a list of valid scot group names from LDAP/AD.

    base
      the search DN that holds your groups.  Could look like: "ou=groups,ou=compname,dc=orgname"

    filter
      the filter to apply to the groups returned by the base dn above.  If
      you start all your scot groups with 'wg-scot'  then the filter would
      be '(| (cn=wg-scot*))'

    attrs
      the attribute that provides the group name, e.g. 'cn'.

user_groups
    This is how SCOT gets a list of groups that a user belongs to.

    base
       the search DN to get the users group membership.  Could look like:
       "ou=accounts,ou=companyname,dc=orgname"

    filter
       The attribute filter to match, in the form of attributename=value.
       Default for SCOT is uid=%s where the %s gets filled in with the user's
       username at access time.  In other words, SCOT does a 
       sprintf("uid=%s", $username);

    attrs
        The attribute that provides the list of groups a user is a member of.
        Default is 'memberOf' but your milage may vary.

Default Groups
^^^^^^^^^^^^^^

SCOT allows you to define the set of default groups that get applied to new alerts, events, entries, etc.

read
  The groups listed in this array are the default read groups.

modify
  The groups listed in this array are the default modify groups.

So if your read is ['wg-scot-ir', 'wg-scot-viewers'] and your modify is [ 'wg-scot-ir' ], a user with only membership in wg-scot-viewers would not be able to modify an entry with the default groups applied.

Admin Group
^^^^^^^^^^^

This setting identifies the name of the group that is allowed to perform
administration functions.

IMAP and Mail Settings
^^^^^^^^^^^^^^^^^^^^^^

These settings point SCOT to your IMAP server and defines the domains and accounts that can send email to SCOT.

mailbox
  Typically "INBOX", but hey whatever works for you.

hostname
  The hostname of the IMAP server, make sure it resolves.

port
  Allows you to set the port if you are running on a non-standard port.  Typically it is 993.

username
  The username associated with the IMAP mailbox that SCOT will use to log into the IMAP server.

password
  The password that will enable SCOT to log into the IMAP server.

ssl
  See "perldoc IO::Socket::SSL" for valid options.

uid
  Default is 1.  Leave it that unless you really know why you are changing it.

ignore_size_errors
  Default is 1. 

approved_alert_domains
  Email from domains not in this list are rejected by SCOT.

approved_accounts
  Accounts in this list are not rejected by SCOT.


