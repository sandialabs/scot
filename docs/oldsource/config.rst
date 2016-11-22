Initially Configuring SCOT
================================

SSL Certs
^^^^^^^^^

SCOT will generate a "snake-oil" certificate upon install.  You will need to replace this as soon as possible with a real SSL certificate.  

Configuration Files
-------------------

The following sections detail the configuration options that are available in SCOT's configuration files.  SCOT comes with configuration templates that you can modify to meet your site requirements and are located in the /opt/scot/etc directory with a "cfg" extension.  The templates are Perl code and heavily documented.  After making changes to them, you should always validate their syntax with the following command: "perl -wc file.cfg"

scot_env.cfg
^^^^^^^^^^^^

The Scot::Env module is created at SCOT startup and holds references to many commonly used modules, common methods, and common configuration variables used by the SCOT application server.  The fields are as follows:

modules
  This hash reference lists the modules that should be instantiated at SCOT start time.  The key is the attribute name of Scot::Env that will hold the reference to the module instance listed in the value.

configs
  This hash reference provided the filename of the configuration files for the modules in the section above.

config_path
  This array reference lists the paths to search for the above config files.  The directories are recursively searched in the order they are listed and the first match will be returned.

authtype
  This option allows you to specify the authentication method for SCOT to use.  Your choices are "Remoteuser", "Ldap" or "Local". See the seciton on Authentication, Authorization and Auditing for more details. 

group_mode
  This option allows you to select if group membership will be controlled by LDAP/AD groups or locally by the SCOT application server.

default_owner
  This allows you to set the username of the default owner of newly created "things" within SCOT.  

default_groups
  This option sets the default group set for both read and modify when group permissions are not explicitly specified upon object creation.

admin_group
  Members of this group have the right to override permissions and other potentially destructive acts.

mojo_defaults
  This hash reference controlls the following:

  secrets
    An array of strings that Mojolicious uses to create secure encrypted session cookies.  Be sure to change these!

  default_expiration
    Session validity duration in seconds.

ldap.cfg
^^^^^^^

My best advice is to buy your LDAP administrator lunch.  There are so
many ways to (mis)configure LDAP, that telling you how to do it is beyond
the scope of this manual.

I can help you with the what the fields in the scot configuration are 
looking for.

hostname
  use the fully qualified hostname for the LDAP/AD server, e.g. "ldap.foo.com"

dn
  The string is the distinguished name and can be provided by your LDAP admin.  typically, it looks like: "cn=something,ou=local config, dc=edu"

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


mail.app.cfg
^^^^^^^^^^^^

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

flair.app.cfg
^^^^^^^^^^^^^

These settings control aspects of the SCOT flairing application.

logfile
  Where you want the flairing app to log.

enrichments
  The configfile that defines the enrichments you with the flair app to use.

scot
  This hash reference tells the flairing application how to communicate with the SCOT application server.

  servername
    The resolvable name of the SCOT server

  username
    The username to use for authentication.

  password
    The password that corresponds to the username above.

  authtype
    What type of authentication is SCOT server performing, "RemoteUser", "LDAP", or "Local".

enrichments.cfg
^^^^^^^^^^^^^^^

The enrichments configuration file is used to initialize the Scot::Util::Enrichments module.  

mappings
  Maps the entity type to an array of enrichments that are available for that type.

configs
  Hash that maps the enrichment name to configuration information for that enrichment

  key
    enrichment name, should match an entry in mappings.

  value
    A hash of information necessary to make the enrichment work.

    type
      Type is required and is one of the following: "native", "internal_link", "external_link".

    module
      The Perl Module name for a "native" enrichment

    url
      Only available to link types, url is a sprintf style string that contains the URL and parameters necessary for call.

    field
      The field from the Entity object to use to perform substitution.  ( sprintf(url, field) )


  
