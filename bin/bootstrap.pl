#!/usr/bin/env perl
use IO::Prompt;
use File::Slurp;
use Proc::InvokeEditor;
use JSON;
use Data::Dumper;

## this program helps the user build initial configuration
##

print <<EOF;

####
#### SCOT initial Configuration Builder
#### 

This program will guide you through the configuration items that need to be set
for SCOT to operate properly.  

The final result of this program will be a js file that you can edit prior to 
insertion into the database.  If you make a typo, you will have a chance to 
correct this at the end.

Let's begin...

##
## ActiveMQ configuration
##

SCOT utilizes ActiveMQ for message passing between components.  Default install of SCOT
will install an instance of ActiveMQ on the same server of SCOT.  You may already have
an ActiveMQ installation that you will wish to utilize, if so, enter the hostaname and
port of where SCOT can communicate with that instance.  Otherwise accept the defaults.

EOF
;

my $amqhost = prompt -d=>'localhost', -p=>'ActiveMQ hostname> ';
my $amqport = prompt -d=>'61613'    , -p=>'ActiveMQ port    > ';

print <<EOF;

##
## LDAP configuration 
##

SCOT can utilize LDAP to authenticate users and to obtain group memberships
When in doubt it is best to involve your LDAP administrator in these settings,
as the problems here can prevent SCOT from working at all. 

DN          
    Distiguished Name, specifies the path to the starting point of LDAP searches.

Password    
    Some LDAPs require a password to bind to the DN
    
Scheme      
    usually set to 'ldap'

Group Search Base
    SCOT needs to know where to search for a list of groups that are SCOT related.

Group Search Filter
    SCOT uses this filter to match a subset of all available groups from above.  
    A good convention would be to start all SCOT related groups with the same prefix,
    say "wg-scot".  This would allow the filter of '(| (cn=wg-scot*))' to work.

Group Search Attribute
    Setting this to 'cn' allows SCOT to pull out just the "name" of the group.

User Groups Base
    SCOT need to know where to search for a particular user's group set.

User Groups Filter
    This is how we will match a particular user.  Typically, 'uid=%s', where %s will
    be filled in at run time with the user's username.

User Groups Attributes
    The attribute to get the group list, typically 'memberOf'.

EOF
;

my $ldaphost    = prompt -p=> 'LDAP hostname> ';
my $ldapdn      = prompt -p=> 'LDAP DN      > ';
my $ldappass    = prompt -p=> 'LDAP Password> ';
my $ldapscheme  = prompt -p=>'LDAP Scheme  > ', -d=> 'ldap';
my $ldap_group_search_base 
                = prompt -p=> 'LDAP Group Search Base      > ';
my $ldap_group_search_filter 
                = prompt -p=> 'LDAP Group Search Filter    > ';
my $ldap_group_search_attrs 
                = prompt -p=> 'LDAP Group Search Attributes> ';
my $ldap_user_groups_base
                = prompt -p=> 'LDAP User Groups Base       > ';
my $ldap_user_groups_filter
                = prompt -p=> 'LDAP User Groups Filter     > ', -d=> 'uid=%';
my $ldap_user_groups_attrs
                = prompt -p=> 'LDAP User Groups Attributes > ', -d=> 'memberOf';


print <<EOF;

##
## IMAP configuration
##

SCOT can communicate with IMAP servers to receive email messages for alerts and intel.
The following values are needed:

Mailbox
    This is the IMAP mailbox to check for email.  Typically, 'INBOX'.

Hostname
    The hostname of the IMAP server

Port
    The IMAP port, typically '993'.

Username
    The account username that is receiving the email messages.  If alert emails are sent to
    'scot-alerts@scot.org', then this value would be 'scot-alerts'.

Password
    The password to access this email account.

SslOpts
    See perldoc IO::Socket::SSL for complete list of options available.  If you are using
    self signed certificates, you will probably need to enter: 'SSL_verify_mode=SSL_VERIFY_NONE'.

Uid
    Imap can use relative or absolute id's for mail messages.  Unless you have a really good 
    reason, leave this set to '1'.

Ignore_size_errors
    Again, unless you know what your are doing, leave this set to '1'.

Approved Domains
    Comma separated list of domains that are permitted to send email to SCOT.

Approved Accounts
    Comman separated list of accounts, e.g. 'tbruner@scot.org' that are allowed to send email to SCOT.

EOF
;

my $imap_mailbox    = prompt -p=> 'IMAP mailbox   > ';
my $imap_hostname   = prompt -p=> 'IMAP Hostname  > ';
my $imap_port       = prompt -p=> 'IMAP Port      > ',-d=> '993';
my $imap_username   = prompt -p=> 'IMAP Username  > ',-d=> 'scot-alerts';
my $imap_password   = prompt -p=> 'IMAP Password  > ';
my $imap_ssl        = prompt -p=> 'IMAP SSL Opts  > ';
my $imap_uid        = prompt -p=> 'IMAP uid       > ',-d=> '1';
my $imap_ignore_size = prompt -p=> 'IMAP Ignore_size_errors > ', -d=> '1';
my $approved_domains = prompt -p=> 'Appoved Domains > ';
my $approved_accounts = prompt -p=> 'Approved Accounts > ';

print <<EOF;

##
## Default Groups
##

Here we define the default read and modify groups.  These comma separated lists will be 
applied to new "Permittable" objects like Alerts, Events, Intel, etc. when no other group
information is available.

If a user matches a group name from their group collection to the groups listed on the "Permittable"
object then that access, read or modify, will be granted to the user.

EOF
;
my $read_groups   = prompt -p=> 'Default Read Group(s)   > ';
my $modify_groups = prompt -p=> 'Default Modify Groups(s)> ';

my $modindex = 1;
my $confindex = 1;

my @modules = (
    {
        id          => $modindex++,
        module      => 'Scot::Util::Imap',
        attribute   => 'imap',
    },
    {
        id          => $modindex++,
        module      => 'Scot::Util::Ldap',
        attribute   => 'ldap',
    },
    {
        id          => $modindex++,
        module      => 'Scot::Util::Messageq',
        attribute   => 'mq',
    },
);

my @ssl = split(/=/,$imap_ssl);
my @okdom   = split(/,/, $approved_domains);
my @okacct  = split(/,/, $approved_accounts);
my @read    = split(/,/, $read_groups);
my @modify  = split(/,/, $modify_groups);


my @configs = (
    {
        id      => $confindex++,
        module  => 'Scot::Util::Imap',
        item    => {
            mailbox     => $imap_mailbox,
            hostname    => $imap_hostname,
            port        => $imap_port,
            username    => $imap_username,
            password    => $imap_password,
            ssl         => \@ssl,
            uid         => $imap_uid,
            ignore_size_errors => $imap_ignore_size,
        }
    },
    {
        id      => $confindex++,
        module  => 'Scot:Env',
        item    => {
            approved_alert_domains  => \@okdom,
            approved_accounts       => \@okacct,
        }
    },
    {
        id      => $confindex++,
        module  => 'Scot::Env',
        item    => {
            default_groups  => {
                read    => \@read,
                modify  => \@modify,
            }
        }
    },
    {
        id      => $confindex++,
        module  => 'Scot::Util::Messageq',
        item    => {
            host    => $amqhost,
            port    => $amqport,
        },
    },
    {
        id      => $confindex++,
        module  => 'Scot::Util::Ldap',
        item    => {
            hostname    => $ldaphost,
            dn          => $ldapdn,
            password    => $ldappass,
            scheme      => $ldapscheme,
            group_search    => {
                base    => $ldap_group_search_base,
                filter  => $ldap_group_search_filter,
                attrs   => $ldap_group_search_attrs,
            },
            user_groups => {
                base    => $ldap_user_groups_base,
                filter  => $ldap_user_groups_filter,
                attrs   => $ldap_user_groups_attrs,
            },
        }
    },
);

print Dumper(@modules);
print Dumper(@configs);
exit 0;

my $cfiletxt;

foreach my $href (@modules) {

    $cfiletxt   .= "db.scotmod.insert(";
    my $json    = encode_json($href);
    $cfiletxt   .= $json . ");\n";

}

foreach my $href (@configs) {
    $cfiletxt   .= "db.config.insert(";
    my $json    = encode_json($href);
    $cfiletx    .= $json . ");\n";
}

my $filename    = prompt -d=> './config.custom.js', -p=> "Enter Filename for Config> ";

my $edited = Proc::InvokeEditor->edit($cfiletxt);
write_file($filname, $edited);



