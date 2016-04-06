package Scot::App::Mail;

use lib '../../../lib';

=head1 Name

Scot::App::Mail

=head1 Description

This Controller, initiates a connection to a IMAP server
gets unread mail
parses it into Alergroups/Alerts
profits

=cut

use Data::Dumper;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::Util::Scot;
use HTML::TreeBuilder;
use Parallel::ForkManager;
use strict;
use warnings;

use Moose;

has env => (
    is          => 'rw',
    isa         => 'Scot::Env',
    required    => 1,
    builder     => '_get_env',
);

sub _get_env {
    return Scot::Env->instance;
}

has max_processes => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 4,
);

has interactive => (
    is      => 'rw',
    isa     => 'Str',
    required    => 1,
    default => 'no',
);

has approved_accounts   => (
    is      => 'rw',
    isa     => 'ArrayRef',
    required=> 1,
    lazy    => 1,
    builder => "_get_approved_accounts",
);

sub _get_approved_accounts {
    my $self    = shift;
    my $env     = $self->env;
    my $value   = $env->get_config_item(__PACKAGE__, "approved_accounts");
    return $value;
}

has approved_alert_domains  => (
    is      => 'rw',
    isa     => 'ArrayRef',
    required=> 1,
    lazy    => 1,
    builder => "_get_approved_alert_domains",
);

sub _get_approved_alert_domains {
    my $self    = shift;
    my $env     = $self->env;
    my $value   = $env->get_config_item(__PACKAGE__, "approved_alert_domains");
    return $value;
}

has scot => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    return Scot::Util::Scot->new();
}

sub run {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $imap    = $env->imap;

    $log->trace("Beginning Alert Email Processing...");

    my @unread  = $imap->get_unseen_mail;

    if ( $self->interactive eq "yes" ) {
        $self->max_processes(0);
    }
    
    my $taskmgr = Parallel::ForkManager->new($self->max_processes);

    MESSAGE:
    foreach my $uid (@unread) {

        next unless $uid;

        my $pid = $taskmgr->start and next;

        if ( $pid == 0 ) {
            $log->trace("[UID $uid] Child process $pid begins working");
            my $imap     = $env->imap;
            my $msg_href = $imap->get_message($uid);
            $self->process_message($msg_href);
            $log->trace("[UID $uid] Child process $pid finishes working");
            $taskmgr->finish;
        }
        if ( $self->interactive eq "yes" ) {
            print "Press Enter to continue, or \"off\" to continue to finish: ";
            my $resp = <STDIN>;
            if ( $resp =~ /off/ ) {
                $self->interactive("no");
            }
        }
    }
    $taskmgr->wait_all_children;
}

sub process_message {
    my $self    = shift;
    my $msghref = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $scot    = $self->scot;

    # is message from approved sender?
    unless ( $self->approved_sender($msghref) ) {
        $log->error("Unapproved Sender is sending message to SCOT");
        $log->error({ filter => \&Dumper, value => $msghref });
        return;
    }

    # is message a health check?
    if ( $self->is_health_check($msghref) ) {
        $log->trace("Health check received...");
        return;
    }

    # we get this far, let's parse it and create alerts/alertgroup
    my $source = $self->get_source($msghref);

    my $json_to_post = $self->$source($msghref);
    my $path         = "/scot/api/v2/alertgroup";

    $log->debug("Json to Post = ", {filter=>\&Dumper, value=>$json_to_post});

    $log->debug("posting to $path");

    my $tx = $scot->post( $path, $json_to_post );

    unless (defined $tx) {
        $log->error("ERROR! Undefined transaction object $path ",
                    {filter=>\&Dumper, value=>$json_to_post});
        return;
    }
    
    if ( $tx->res->json->{status} ne "ok" ) {
        $log->error("Failed posting new alertgroup mgs_uid:", $msghref->{imap_uid});
        $log->debug("tx->res is ",{filter=>\&Dumper, value=>$tx->res});
        $env->imap->mark_uid_unseen($msghref->{imap_uid});
        return;
    }
    $log->trace("Created alertgroup ". $tx->res->json->{id});
}

sub get_source {
    my $self    = shift;
    my $href    = shift;
    my $from    = $href->{from};
    my $subject = $href->{subject};

    return "splunk"     if ( $subject =~ /splunk alert/i );
    return "fireeye"    if ( $from =~ /fireeye/i );
    return "ascan"      if ( $subject =~ /ascan daily report/i );
    return "sep"        if ( $from =~ /workflow/i );
    return "sep2"       if ( $from =~ /symantec/i );
    return "mds"        if ( $subject =~ /mds alert/i);
    return "mds2farm"   if ( $subject =~ /mds to farm/i);
    return "sourcefire" if ( $subject =~ /auto generated email/i );
    return "forefront"  if ( $subject =~ /microsoft forefront/i );
    return "generic";
}

sub approved_sender {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $domains = $env->approved_alert_domains;
    my $senders = $env->approved_accounts;
    my $this_sender = $href->{from};
    my $log     = $env->log;

    $this_sender =~ s/<(.*)>/$1/;
    $log->trace("Checking if Sender $this_sender is approved");


    foreach my $as (@$senders) {
        $log->trace("comparing $as");
        if ( $as eq $this_sender ) {
            $log->trace("you are approved!");
            return 1;
        }
    }
    my $this_domain = (split(/\@/, $this_sender))[1];
    $log->trace("not explicitly named, checking domain $this_domain");

    foreach my $ad ( @$domains ) {
        $log->trace("comparing to domain $ad");
        if ( $ad eq $this_domain ) {
            $log->trace("approved domain");
            return 1;
        }
    }
    return undef;
}

sub is_health_check {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Checking if this is a health check message");

    my $subject = $href->{subject};

    if ( $subject =~ /SCOT-ALERTS Health Check/i ) {
        $log->trace("It is!");
        # ok, last version had this, but I think it was a kludge
        # keeping this to ignore them when they come in.
        # but a better check might be to see if we haven't received
        # any alerts in x number of minutes
        return 1;
    }
    return undef;
}

sub splunk {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;

    $log->trace("parsing Splunk alert of ",{filter=>\&Dumper, value=>$href});

    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds) ],
    };
    my $body    = $href->{body_html} // $href->{body_plain};

    $log->trace("Parsing Splunk Message Body");
    $log->trace("Body is : ",{filter=>\&Dumper,value=>$body});

    my  $tree   = HTML::TreeBuilder->new;
        $tree   ->implicit_tags(1);
        $tree   ->implicit_body_p_tag(1);
        $tree   ->parse_content($body);

    unless ( $tree ) {
        $log->error("Parsing error!");
        die "Parsing error!";
    }

    # splunk 6 now puts the search name in a table!
    # and omits search terms

    my $text        = $tree->as_text( skip_dels => 1 );
    $text           =~ m/ Name: '(.*?)'[ ]+Query/;
    # my $alertname   = $1;
    #$text           =~ m/Query Terms: '(.*?)'[ ]+Link/;
    #(my $search = $1 )     =~ s/\\"/"/g; 
    #$search      = encode_entities($search);

    my $top_table = ( $tree->look_down('_tag', 'table') )[0];
    my @top_table_tds = $top_table->look_down('_tag', 'td');
    my $alertname   = $top_table_tds[0]->as_text;
    my $search      = "splunk is not sending the search terms";
    if ( scalar(@top_table_tds) > 1 ) {
        $search      = $top_table_tds[1]->as_text;
    }

    my $table   = ( $tree->look_down('_tag', 'table') )[1];

    unless ($table) {
        $log->error("No Tables in Splunk Email!");
        return [],[];
    }

    my @rows    = $table->look_down('_tag', 'tr');
    my $header  = shift @rows;
    my @columns = map { $_->as_text; } $header->look_down('_tag', 'th');

    if (scalar(@columns) == 0) {
        # it seems that micro$oft outlook clients will rewrite valid
        # splunk HTML into Fugly broken HTML when forwarding.
        # this case deals with a splunk email sent to a user who then
        # forwards it to scot using a outlook client.
        @columns = map { $_->as_text; } $header->look_down('_tag', 'td');
    }

    my @results = ();
    my @msg_id_entities;

    my $empty_col_replace   = 1;

    foreach my $row (@rows) {
        my @values  = $row->look_down('_tag','td');
        my %rowres  = (
            alert_name  => $alertname,
            search      => $search,
            columns     => \@columns,
        );
        for ( my $i = 0; $i < scalar(@values); $i++ ) {
            my $colname         = $columns[$i];
            unless ($colname) {
                $colname    = "c" . $empty_col_replace++;
                $log->error("EMPTY colname detected! replacing with $colname");
                $log->debug("table is: ".Dumper($table->as_HTML));
            }
            my $value           = $values[$i]->as_text;
            if ( $colname eq "MESSAGE_ID" ) {
                push @msg_id_entities, $value;
                $value = qq|<span class="entity message_id" data-entity-value="$value" data-entity-type="message_id">$value</span>|;
            }
            $rowres{$colname}   = $value;
        }
        push @results, \%rowres;
    }
    $json->{data}   = \@results;
    $json->{columns} = \@columns;
    return $json;
}

sub fireeye {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds) ],
    };
    my $body    = $href->{body_plain};

    $log->trace("Parsing Fireeye Message Body");

    my $thisjson    = JSON->new->relaxed(1);
    $body       =~ s/\012\015?|\015\012?//g;
    my $decoded;
    eval {
       $decoded = $thisjson->decode($body);
    };
    my $html    = Dumper($decoded);

    my $data    = {
        fireeye_alert => $html,
    };

    $json->{data}   = [ $data ];
    $json->{columns}= keys %$data;
    return $json;
}

sub ascan {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds) ],
    };
    my $body    = $href->{body_html} // $href->{body_plain};

    $log->trace("Parsing Ascan Message Body");

    my $thisjson    = JSON->new()->relaxed(1);
    my $data        = $thisjson->decode($body);

    my @cols    = keys %{ $data->{mds_alerts}->[0] };

    $json->{data}   = [ $data ];
    $json->{columns} = \@cols;
    return $json;
}

sub sep {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds) ],
    };
    my $body    = $href->{body_html} // $href->{body_plain};

    $log->trace("Parsing SEP Message Body");

    my  $tree   = HTML::TreeBuilder->new;
        $tree   ->implicit_tags(1);
        $tree   ->implicit_body_p_tag(1);
        $tree   ->parse_content($body);

    my @tables  = $tree->look_down('_tag', 'table');
    my @results = ();

    my $dblookup = {
        0   => "SEM5 : SRN SEP 11 clients",
        1   => "SEM12 : SRN SEP 12 clients",
        2   => "SEM11 : Dev",
        3   => "SEM12 : Dev",
    };
    my $dbindex = 0;
    my @columns;

    foreach my $table (@tables) {

        my @rows    = $table->look_down('_tag', 'tr');
        
        my $header  = shift @rows;
        @columns    = map { $_->as_text; } $header->look_down('_tag','th');

        foreach my $row (@rows) {
            
            my @values  = $row->look_down('_tag','td');
            my %rowres  = (
                alert_name  => "Symantec Cyber Application Scan",
                search      => $dblookup->{$dbindex},
                columns     => \@columns,
            );
            for ( my $i = 0; $i < scalar(@values); $i++ ) {
                $rowres{$columns[$i]} = $values[$i]->as_text;
            }
            push @results, \%rowres;
        }
        $dbindex++;
    }
    $json->{data}       = \@results;
    $json->{columns}    = \@columns;
    return $json;
}

sub sep2 {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds) ],
    };
    my $body    = $href->{body_html} // $href->{body_plain};

    $log->trace("Parsing SEP2 Message Body");

    my @lines   = split /\012\015?|\015\012?/, $body;
    my @columns = ();
    my $data;   
    
    foreach my $line (@lines) {
        my ($key, $value) = split(/: /, $line, 2);
        next unless (defined $key);
        $key =~ s/ /_/g;
        $key =~ s/\./,/g;
        push @columns, $key;
        $data->{$key} = $value;
    }

    $json->{data}   = [ $data ];
    $json->{columns}    = \@columns;
    return $json;
}

sub mds {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds) ],
    };
    my $body    = $href->{body_html} // $href->{body_plain};

    $log->trace("Parsing Ascan Message Body");

    $body =~ s/<br>/<br>:::/g;

    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->implicit_body_p_tag(1);
       $tree    ->parse_content($body);

    my $text    = $tree->as_text( skip_dels => 1 );

    my @columns     = ();
    my %results     = ();
    my @freetext    = ();

    foreach my $line ( split(/:::/, $text) ) {
        my ( $key, $value ) = split(/ = /,$line);
        if ( $key =~ /\./ ) {
            # periods in a key are a no-no
            $key =~ s/\./&#46;/g;
        }
        if ( defined $key and defined $value ) {
            $results{$key}  = $value;
            push @columns, $key;
        }
        else {
            push @freetext, $line;
        }
    }
    $results{freetext} = join('\n', @freetext);
    push @columns, "freetext";
    $json->{data}       = [ \%results ];
    $json->{columns}    = \@columns;
    return $json;
}

sub mds2farm {
    my $self    = shift;
    my $href    = shift;
    my $log     = $self->env->log;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email mds2farm) ],
    };
    my $body    = $href->{body_html};

    my  $tree   = HTML::TreeBuilder->new;
        $tree   ->implicit_tags(1);
        $tree   ->implicit_body_p_tag(1);
        $tree   ->parse_content($body);

    my $table   = ( $tree->look_down('_tag', 'table') )[0];
    unless ($table) {
        return $json;
    }
    my @rows    = $table->look_down('_tag', 'tr');
    my $header  = shift @rows;
    my @columns = map { $_->as_text; } $header->look_down('_tag', 'th');

    if ( scalar(@columns) == 0 ) {
        # Outlook breaks TH sometimes
        @columns = map { $_->as_text; } $header->look_down('_tag', 'td');
    }
    my @results = ();
    my @msg_id_entities;

    my $empty_col_replace   = 1;

    foreach my $row (@rows) {
        my @values  = $row->look_down('_tag','td');
        my %rowres  = (
            alert_name  => "MDS to Farm Daily Domain Listing",
            columns     => \@columns,
        );
        for ( my $i = 0; $i < scalar(@values); $i++ ) {
            my $colname         = $columns[$i];
            unless ($colname) {
                $colname    = "c" . $empty_col_replace++;
                $log->error("EMPTY colname detected! replacing with $colname");
                $log->debug("table is: ".Dumper($table->as_HTML));
            }
            my $value           = $values[$i]->as_text;
            $rowres{$colname}   = $value;
        }
        push @results, \%rowres;
    }
    $json->{data}       = \@results;
    $json->{columns}    = \@columns;
    return $json;
}

sub sourcefire {
    my $self    = shift;
    my $href    = shift;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email sourcefire) ],
    };
    my $regex   = qr{ \[(?<sid>.*?)\] "(?<rule>.*?)" \[Impact: (?<impact>.*?)\] +From "(?<from>.*?)" at (?<when>.*?) +\[Classification: (?<class>.*?)\] \[Priority: (?<pri>.*?)\] {(?<proto>.*)} (?<rest>.*) *};

    my $body    = $href->{body_html} // $href->{body_plain};
       $body    =~ s/[\n\r]/ /g;
       $body    =~ m/$regex/g;

    my $rest    = $+{rest};
    my ($fullsrc, $fulldst)     = split(/->/, $rest);
    my ($srcip, $srcport)       = split(/:/, $fullsrc);
    my ($dstip, $dstport)       = split(/:/, $fulldst);
    
    $json->{data}    = {
        sid             => $+{sid},
        rule            => $+{rule},
        impact          => $+{imapct},
        from            => $+{from},
        when            => $+{when},
        class           => $+{class},
        priority        => $+{pri},
        proto           => $+{proto},
        srcip           => $srcip,
        srcport         => $srcport,
        dstip           => $dstip,
        dstport         => $dstport,
    };
    $json->{columns}    = [
        qw(sid rule impact from when class priority proto scrip srcport dstip dstport)
    ];
    return $json;
}

sub forefront {
    my $self    = shift;
    my $href    = shift;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [],
        source      => [ qw(email forefront) ],
    };
    my $data    = {};
    my @columns = ();

    my $body    = $href->{body_html} // $href->{body_plain};
    my %upper   = $body =~ m/[ ]{4}(.*?):[ ]+\"(.*?)\"/gms;
    my %lower   = $body =~ m/[ ]{6}(.*?):[ ]*(.*?)$/gms;

    foreach my $href (\%upper, \%lower) {
        while ( my ($k, $v) = each %$href ) {
            $k  =~ s/^[ \n\r]+//gms;
            $k  =~ s/ /_/g;
            $k  =~ s/\./_/g;
            push @columns, $k;
            $data->{$k} = $v;
        }
    }
        
    $json->{data} = [ $data ];
    $json->{columns} = \@columns;

    return $json;
}

sub generic {
    my $self    = shift;
    my $href    = shift;
    my $json    = {
        subject     => $href->{subject},
        message_id  => $href->{message_id},
        body_plain  => $href->{body_plain},
        body        => $href->{body_html},
        data        => [{
            alert   => $href->{body_plain},
            columns => [qw(alert)],
        }],
        source      => [ qw(email generic) ],
        columns     => [ qw(alert) ],
    };
    return $json;
}

1;
