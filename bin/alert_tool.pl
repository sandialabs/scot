#!/usr/bin/env perl
use lib '../lib';

use IO::Prompt;
use Data::Dumper;
use Mojo::UserAgent;
use JSON;

my $ua      = Mojo::UserAgent->new;
my $json    = JSON->new;

my $user    = prompt("Scot username: ");
my $pass    = prompt("Password     : ", -e => '*');
my $host    = prompt("Scot Hostname: ");

my $url     = "https://$user:$pass\@$host/scot";

while ( my $command = prompt "[C]reate or [Q]uery? " ) {
    if ( $command =~ /^[cC]/ ) {
        print <<EOF;
You will now be prompted for the various pieces of data
necessary to create an alertgroup.  The only tricky one
is the Data field, which needs to be a JSON array, e.g.:

[ { "text": "cool stuff", "value": 123 }, { "text": "more stuff", "value": "xyz" } ]

EOF

        my $sources = prompt "Enter sources (comma seperated) : ";
        my $subject = prompt "Enter subject                   : ";
        my $data    = prompt "Enter Data (in JSON fmt)        : ";
        my $href    = $json->decode($data);
        unless (defined $href) {
            die "data did not parse!";
        }
        my $tags    = prompt "Enter tags (comma seperated)    : ";
        my $rg      = prompt "Enter read groups (comma sep)   : ";
        my $mg      = prompt "Enter modify groups (comma sep) : ";
        
        my @sources = split(/,/,$sources);
        my @tags    = split(/,/,$tags);
        my @read    = split(/,/,$rg);
        my @modify  = split(/,/,$mg);


        print "JSON decoded it as : ".Dumper($href);

        my $postdata    = {
            sources     => \@sources,
            subject     => $subject . "",
            data        => $href,
            tags        => \@tags,
            readgroups  => \@read,
            modifygroups=> \@modify,
        };

        print "Submitting the following post data:\n";
        print Dumper($postdata)."\n";

        my $tx  = $ua->post($url."/alertgroup" => json => $postdata);

        if ( my $res = $tx->success) {
            print $res->body;
        }
        else {
            my $err = $tx->error;
            print "$err->{code} response: $err->{message}\n" if $err->{code};
            print "Connection error: $err->{message}\n";
        }
    }
    else {
        my $alert_id    = prompt "Enter alert_id : ";
        my $href        = $ua->get($url."/alert/$alert_id");
        print "Server Response: \n".Dumper($href->body)."\n";
    }
}


