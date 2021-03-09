Unified Email Processing
------------------------

# Processor.pm

Connects to a list of email inboxes.  Retrieves the messages and normalizes the data.  Submits normalized data to various queues for further processing.

Rev 1. will utilize a config file to control behavior.  The config will contain a list of mailboxes to monitor.  The list will consist of objects in the following format:

{
    name        => 'short name of inbox',
    description => 'longer description',
    mailserver  => 'mail.domain.com',
    port        => 993,
    username    => 'inbox_owner_username',
    password    => 'password_for_inbox_owner',
    ssl_opts    => [
        'SSL_verify_mode', 1
    ], 
    queue       => '/queue/to_submit_normalized_data_to',
    frequency   => $seconds_between_fetches,
}

# Responders

Modules in the Scot/Email/Responder directory are responsible for the next step of processing of the email.  Multiple workers multiplex on the queue they are responsible for.  The worker picks up a normalized message and then parses the message and submits to the SCOT database.  Finally, they generate a /topic/scot message to inform browsers and the flair engine to begin their work.

# Parsers

Modules in the Scot/Email/Parser directory parse different type of messages and prepare the data from submission to the SCOT Database.

## Alert Parsers

Alert parsers parse the various types of Emails that will be turned into Alerts

* Splunk
* Generic
* CI parser

## Event Parsers

Event Parser turns emails in specific format into an Event

* COE Event

## Dispatch Parser

Dispatch Parsers turn emails into dispatches

* ?

# IMAP.pm

Does the dirty work of talking to the Imap Server

get_message returns the following:

# message = (
#   imap_uid
#   envelope
#   subject
#   from
#   to
#   when
#   message_id
#   body_html
#   body_plain
# )
