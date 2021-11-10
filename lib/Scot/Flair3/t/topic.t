#!/usr/bin/env perl

use Net::Stomp;
use JSON;
use File::Slurp;
use Data::Dumper;

my $flag    = "./rcv.txt";
system("cat /dev/null > $flag");

my $stomp    = Net::Stomp->new({
    hostname    => 'localhost',
    port        => 61613,
});

$stomp->connect();
$stomp->subscribe({
    destination => '/topic/scot',
    ack         => 'client',
    'activemq.prefetchSize' => 1
});

print "writing pid\n";
write_file($flag, $$."\n");

while (1) {
    print "Listening on /topic/scot...\n";
    my $frame   = $stomp->receive_frame;
    $stomp->ack({frame => $frame});
    print "rcv frame\n";
    my $body    = decode_json($frame->body);
    print Dumper($body);
    my $string  = sprintf("%s %d\n", $body->{data}->{type}, $body->{data}->{id});
    print "$string\n";
    my $res     = append_file($flag, $string);
    print "res = $res\n";
}



    

