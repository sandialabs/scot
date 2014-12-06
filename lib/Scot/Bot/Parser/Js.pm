package Scot::Bot::Parser::Js;

use lib '../../../../lib';
use strict;
use warnings;
use v5.10;

use Mail::IMAPClient;
use Mail::IMAPClient::BodyStructure;
use MIME::Base64;
use MongoDB;
use Scot::Model::Alert;
use Scot::Util::Mongo;
use IPC::Run qw(run timeout);
use JSON qw(decode_json to_json);
use Data::Dumper;

use Moose;
extends 'Scot::Bot::Parser';

has 'parser_id'   => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);


sub parse_body {
    my $self        = shift;
    my $bodyhref    = shift;
    my $log         = $self->env->log;
    my $mongo       = $self->env->mongo;
    my $parser_id   = $self->parser_id;
    my $body        = $bodyhref->{html} // $bodyhref->{plain};

    $log->debug('Going to use parser_id '.$parser_id);

    my $parser      = $mongo->read_one_document({
       collection => 'parsers',
       match_ref  => {'parser_id' => ($parser_id + 0)}
    });
    $log->debug('retrieved parser mongo object '.Dumper($parser));

    my $js = $parser->{'js'};
    my $input = {'html' => $body, 'js' => $js};
    
    my $in;
    eval {
       $in = to_json($input);
    };
    if ($@)  {        
        print "\n\n\n\n\n";
        print "ISSUE RUNNING TO_JSON\n$in";
        return undef;
    }
    $log->debug('Going to sent following JSON as input '. $in);

    my $out = '';
    my $err = '';
    eval {
       my @cmd = qw(/opt/sandia/webapps/phantomjs/bin/phantomjs /opt/sandia/webapps/phantomjs/scot/parser.js);
       run \@cmd, \$in, \$out, \$err; #, timeout(5);
    };
    if ($@) {
        print "\n\n\n\n\n";
        print "ISSUE RUNNING PHANTOM\n";
        return undef;
    }
    #$log->debug('ran Phantom, output is '.Dumper($out));        

    my $result;
    my @columns     = {};
    eval {
       $result = decode_json($out);
    };
    if ($@) {
        print "\n\n\n\n\n\n\n";
        print "ISSUE RUNNING DECODE_JSON\n$out";
        return undef;
    }
    $log->debug('Decoded JSON'.Dumper($result));
    foreach my $occurance (@{$result}) {
       @columns = keys %{$occurance};  
    }
    return $result, \@columns;
}

__PACKAGE__->meta->make_immutable;
1;
