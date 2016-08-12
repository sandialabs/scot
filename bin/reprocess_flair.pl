#!/usr/bin/env perl

use v5.18;
use lib '../lib';
use Scot::Util::Config;
use Scot::Util::Scot;
use Scot::Util::Mongo;
use Scot::Env;
use Scot::App::Flair;
use IO::Prompt;
use DateTime;
use DateTime::Format::Strptime;
use HTML::Entities;
use Getopt::Long qw(GetOptions);

my $colname;
my $type;
GetOptions(
    "c=s"   => \$colname,
    "t=s"   => \$type,
) or die <<EOF

Invalid option
    -c=[alert|entry]
    -t=[date|flag]
EOF
;


my $configobj = Scot::Util::Config->new({
    file    => 'reproc.cfg',
    paths   => [ '/opt/scot/etc' ],
});

my $config  = $configobj->get_config;

my $log     = Scot::Util::Logger->new($config->{log});
my $scot    = Scot::Util::Scot->new({
    log     => $log,
    servername  => $config->{scot}->{servername},
    username    => $config->{scot}->{username},
    password    => $config->{scot}->{password},
    authtype    => $config->{scot}->{authtype},
});
my $mongo   = Scot::Util::Mongo->new($config->{mongo});
my $extractor   = Scot::Util::EntityExtractor->new({ log => $log });
my $imgmunger   = Scot::Util::ImgMunger->new({ log => $log });


say "---";
say "--- SCOT Flair Reprocessor";
say "---";
say "";

while ( $colname ne "alert" and $colname ne "entry" ) {
    $colname = prompt "Enter Collection [alert|entry]: ";
}

say "$colname may be reprocessed for flair in one of two ways:";
say "    1.  all $colname after a given epoch (date)";
say "    2.  all $colname with an unset parsed flag (flag)";
say "    3.  commas seperated ids";
say "";

while ( $type ne "date" and $type ne "flag" and $type ne "ids") {
    $type = prompt "Enter reprocess type [date|flag|ids]: ";
}

my $collection = $mongo->collection(ucfirst($colname));
my $match;

my $force   = 0;

if ( $type eq "ids") {
    my $id = prompt "Enter ids: ";

    my @ids = map { $_ += 0 } split(/, */, $id);

    $match = { id => { '$in' => \@ids }};

    say "looking for $colname $id...";

}
elsif ( $type eq "date" ) {

    my $begin = get_date("begin");
    my $end   = get_data("end");

    $match  = {
        created  => { 
            '$gte' => $begin,
            '$lte' => $end,
        },
    };

    say "Looking for $colname on or after $begin and before $end...";

}
else {

    say "Looking for unflagged $colname...";

    $match  = {
        parsed  => { '$ne' => 1 },
    };
}

my $cursor  = $collection->find($match);
   $cursor->sort({id => -1});

while ( my $obj = $cursor->next ) {
    say "processing $colname ". $obj->id;

    if ($type eq "flag") {
        my $potentially_flaired;
        if ( $colname eq "alert" ) {
            $potentially_flaired    = $obj->data_with_flair;
        }
        else {
            $potentially_flaired    = $obj->body_flair;
        }
        if ( $potentially_flaired ) {
            if ( $potentially_flaired =~ /entity/ ) {
                say "$colname ".$obj->id." appears to have been flaired...";
                $obj->update_set(parsed => 1);
                next;
            }
        }
        if ( $colname eq "alert" ) {
            process_alert($obj);
        }
        else {
            process_entry($obj);
        }
    }
    else {
        if ( $colname eq "alert" ) {
            process_alert($obj);
        }
        else {
            process_entry($obj);
        }
    }
}

sub get_date {
    my $type       = shift;
    my $dstr       = prompt "Enter $type Date [yyyy-mm-dd hh:mm:ss]: ";
    my $strp       = DateTime::Format::Strptime->new(
        pattern   => '%y-%m-%d %H:%M:%S',
        locale    => 'en_US',
        time_zone => 'America/Denver',
    );
    my $dt         = $strp->parse_datetime($dstr);
    my $epoch      = $dt->epoch;
    return $epoch;
}

sub process_alert {
    my $alert   = shift;
    my $data    = $alert->data;
    my $flair;
    my @entities;
    my %seen;

    TUPLE:
    foreach my $key (keys %{$data}) {
        say "    $key ";
        my $value   = $data->{$key};
        my $encoded = '<html>'. encode_entities($value). '</html>';

        if ( $key   =~ /^message_id$/i ) {
            push @entities, { value => $value, type => "message_id" };
            $flair->{$key} = qq|<span class="entity message_id" |.
                             qq| data-entity-value="$value" |.
                             qq| data-entity-type="message_id">$value</span>|;
            next TUPLE;
        }
        if ( $key =~ /^columns$/i ) {
            $flair->{$key} = $value;
            next TUPLE;
        }
        
        my $href       = $extractor->process_html($encoded);
        $flair->{$key} = $href->{flair};

        foreach my $entity (@{$href->{entities}}) {
            my $evalue  = $entity->{value};
            my $etype   = $entity->{type};
            unless ( defined $seen{$evalue} ) {
                push @entities, $entity;
                $seen{$evalue}++;
            }
        }
    }
    my $tx = $scot->put('alert', $alert->id, {
        data_with_flair => $flair,
        entities        => \@entities,
        parsed          => 1,
    });
}

sub process_entry {
    my $entry   = shift;
    my $body    = $entry->body;
    my $data    = $imgmunger->process_html($body, $entry->id);
    my $href    = $extractor->process_html($data);
    my $json    = {
        parsed  => 1,
        body_plain  => $href->{text},
        body_flair  => $href->{flair},
        entities    => $href->{entities},
    };
    my $tx = $scot->put('entry', $entry->id, $json);
}
