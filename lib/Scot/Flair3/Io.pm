package Scot::Flair3::Io;

use strict;
use warnings;
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use utf8;
use lib '../../../lib';

use Data::Dumper;
use DateTime;
use Try::Tiny;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);
use Log::Log4perl;
use Net::Stomp;
use Sys::Hostname;
use Data::GUID;
use JSON;
use File::Magic;
use File::Copy;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);
use File::Slurp;
use File::Path qw(make_path);
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use Meerkat;

has queue   => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
);

has topic   => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
);

has log => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    required=> 1,
    builder => '_build_log',
);

sub _build_log ($self) {
    my $logname = "FlairLog";
    my $log     = Log::Log4perl->get_logger($logname);
    my $pattern = "%d %7p [%P] %15F{1}: %4L %m%n";
    my $layout  = Log::Log4perl::Layout::PatternLayout->new($pattern);
    my $appender= Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::File',
        name        => 'flair_log',
        filename    => '/var/log/scot/flair.log',
        autoflush   => 1,
        utf8        => 1,
    );
    $appender->layout($layout);
    $log->add_appender($appender);
    $log->level("DEBUG");
    return $log;
}

has mongo   => (
    is      => 'ro',
    isa     => 'Meerkat',
    required=> 1,
    builder => '_build_mongo',
);

sub _build_mongo ($self) {
    return Meerkat->new(
        model_namespace         => 'Scot::Model',
        collection_namespace    => 'Scot::Collection',
        database_name           => 'scot-prod',
        client_options          => {
            host        => 'localhost',
            w           => 1,
            find_master => 1,
            socket_timeout_ms => 600000,
        }
    );
}

has stomp  => (
    is      => 'ro',
    isa     => 'Net::Stomp',
    required=> 1,
    builder => '_build_stomp',
);

sub _build_stomp ($self) {
    my $stomp_host  = "localhost";
    my $stomp_port  = 61613;

    my $stomp   = Net::Stomp->new({
        hostname    => $stomp_host,
        port        => $stomp_port,
        # ssl       => 1,
        # ssl_options=> {}
    });

    die "Failed to initialize Net::Stomp!" if (! defined $stomp );
    $stomp->connect();
    return $stomp;
}

has ua  => (
    is          => 'ro',
    isa         => 'LWP::UserAgent',
    required    => 1,
    builder     => '_build_ua',
);

sub _build_ua ($self) {
    my $agent   = LWP::UserAgent->new(
        env_proxy   => 1,
        timeout     => 10,
    );
    $agent->ssl_opts(
        ssl_verify_mode => 1,
        verify_hostname => 1,
        ssl_ca_path     => '/etc/ssl/certs',
    );
    $agent->env_proxy;
    $agent->agent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit  /537.36 (KHT  ML, like Gecko) Chrome/41.0.2227.1 Safari/537.36');
    return $agent;
}

sub get_timer ($self, $title) {
    my $start   = [ gettimeofday ];
    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [ gettimeofday ]);
        return $elapsed;
    };
}

sub send_mq ($self, $dest, $href) {
    my $stomp = $self->stomp;
    $self->_clear_stomp if ! $stomp;
    
    $href->{pid}        = $$;
    $href->{hostname}   = hostname;
    my $guid            = Data::GUID->new;
    my $gstring         = $guid->as_string;
    $href->{guid}       = $gstring;
    my $body            = encode_json($href);
    my $length          = length($body);
    my $rcvframe;

    try {
        $stomp->send_transactional({
            destination     => $dest,
            body            => $body,
            'amq-msg-type'  => 'text',
            'content-length'=> $length,
            persistent      => 'true',
        }, $rcvframe);
    }
    catch {
        $self->log->error("Error Sending STOMP message: $_");
        $self->log->error($rcvframe->as_string);
    };
}


sub receive_frame ($self) {
    return $self->stomp->receive_frame;
}

sub ack_frame ($self, $frame) {
    $self->stomp->ack({frame => $frame});
}

sub decode_frame ($self, $frame) {
    my $body    = $frame->body;
    my $headers = $frame->headers;
    my $json    = decode_json($body);
    my $message = {
        headers => $headers,
        body    => $json,
    };
    return $message;
}

sub nack_frame ($self, $frame) {
    $self->stomp->nack({frame => $frame});
}

sub connect_to_amq ($self, $queue, $topic) {
    my $log     = $self->log;
    my $stomp   = $self->stomp;

    $stomp->connect();
    $stomp->subscribe({
        destination             => $queue,
        ack                     => 'client',
        'activemq.prefetchSize' => 1,
    });
    $log->debug("Subscribed to $queue");

    $stomp->subscribe({
        destination             => $topic,
        ack                     => 'client',
        'activemq.prefetchSize' => 1,
    });
    $log->debug("Subscribed to $topic");
}

sub update_entry ($self, $update) {

    my $entry   = $update->{entry};
    my $edb     = $update->{edb};
    my $flair   = $update->{flair};
    my $text    = $update->{text};

    my $mongo_update  = {
        parsed      => 1,
        body_plain  => $text,
        body_flair  => $flair,
    };
    try {
        $entry->update({'$set' => $mongo_update});
    }
    catch {
        $self->log->error("Failed to update entry ".$entry->id.": $_");
    };

    $self->send_entities_to_enricher($edb);
    $self->send_entry_updated_messages($entry);
    $self->link_entities($entry, $edb);
}


sub alter_entry_body ($self, $entry, $html) {
    try {
        $entry->update({'$set' => { body => $html }});
    }
    catch {
        $self->log->error("Failed to update Entry ".$entry->id." body: $_");
    };
}

sub retrieve ($self, $message) {
    my $type    = $message->{type};
    my $id      = $message->{id}+0;
    my $col     = $self->mongo->collection(ucfirst($type));
    my $obj     = $col->find_iid($id);
    return $obj;
}

sub get_alerts ($self, $alertgroup) {
    my $query   = {
        alertgroup  => $alertgroup->id,
    };
    my $col     = $self->mongo->collection('Alert');
    my $cursor  = $col->find($query);
    my @alerts  = ();
    while (my $obj = $cursor->next) {
        push @alerts, $obj;
    }
    return wantarray ? @alerts : \@alerts;
}

sub update_alertgroup ($self, $alertgroup, $edb, $workertype) {
    my $update  = {
        '$set'  => { parsed => 1 }
    };
    $alertgroup->update($update);
    $self->link_entities($alertgroup, $edb);
    $self->send_alertgroup_updated_message($alertgroup);
}

sub send_alertgroup_updated_message ($self, $alertgroup) {
    my $id  = $alertgroup->id;
    $self->send_mq('/topic/scot', {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'alertgroup',
            id      => $id,
        }
    });
}

sub update_alert ($self, $update) {

    my $alert   = $update->{alert};
    my $flair   = $update->{flair};
    my $text    = $update->{text};
    my $edb     = $update->{edb};

    my $mongo_update  = { 
        '$set'  => {
            parsed => 1, data_with_flair => {} 
        }
    };
    foreach my $key (keys %$flair) {
        $mongo_update->{'$set'}->{data_with_flair}->{$key} = $flair->{$key};
    }
    $alert->update($mongo_update);
    $self->link_entities($alert, $edb);
    $self->send_alert_update_message($alert);
}

sub send_alert_update_message ($self, $alert) {
    my $id  = $alert->id;
    $self->send_mq('/topic/scot', {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'alert',
            id      => $id,
        }
    });
}

sub send_entities_to_enricher ($self, $edb) {
    my $entities    = $edb->{entities};
    my $msg = {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'entity',
        }
    };
    foreach my $type (keys %$entities) {
        foreach my $value (keys %{$entities->{$type}}) {
            my $entity = $self->get_entity($type,$value);
            $msg->{data}->{id} = $entity->id;
            $self->send_mq('/queue/enricher', $msg);
        }
    }
}

sub get_entity ($self, $type, $value) {
    my $col     = $self->mongo->collection('Entity');
    my $obj     = $col->find_one({type => $type, value => $value});
    return $obj;
}

sub send_entry_updated_messages ($self, $entry, $workertype) {
    my $id      = $entry->id;
    my $target  = $entry->target;
    my $msg     = {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'entry',
            id      => $id,
        }
    };
    $self->send_mq('/topic/scot', $msg);
    $msg->{data}->{type}    = $target->{type};
    $msg->{data}->{id}      = $target->{id};
    $self->send_mq('/topic/scot', $msg);

    if ( $workertype eq "core" ) {
        $self->log->trace("Sending Core Flaired Entry $id to Udef flair queue");
        $self->send_mq('/queue/udflair', {
            action  => 'updated',
            data    => {
                who     => 'scot-flair',
                type    => 'entry',
                id      => $id,
            }
        });
    }
}

sub link_entities ($self, $obj, $edb) {
    my $obj_type    = $self->get_object_type($obj);
    my $target;
    if ( $obj_type eq "Entry") {
        $target = $obj->target;
    }

    my $entities    = $edb->{entities};
    TYPE:
    foreach my $type (keys %$entities) {
        my $bytype = $edb->{$type};
        ENTITY:
        foreach my $value (keys %$bytype) {
            my $entity = $self->get_entity($type, $value);
            my $status = $entity->status;

            next ENTITY if (defined $status and $status eq "untracked");

            my $link   = $self->link_objects($obj, $entity);
            if ( defined $target ) {
                my $slink = $self->link_objects($entity, $target);
            }
        }
    }
}

sub link_objects ($self, $o1, $o2) {
    my $col     = $self->mongo->collection('Link');
    my $link    = try {
        $col->link_objects($o1, $o2);
    }
    catch {
        $self->log->error("Failed to create Link between: ".
            ref($o1)."[".$o1->id."] and ".
            ref($o2)."[".$o2->id."]");
    };
    return $link;
}

sub get_object_type ($self, $obj) {
    return (split(/::/,ref($obj)))[-1];
}

sub get_active_entitytypes ($self) {
    my $query   = { status => "active" };
    my $col     = $self->mongo->collection("Entitytype");
    my $count   = $col->count($query);
    my $cursor  = $col->find($query);
    return $cursor;
}

sub create_file_from_uri ($self, $uri) {
    my $newuri  = '';
    my $tmpfile; 

    if ($self->is_data_uri($uri)) {
        my ($mime, $enc, $data) = $self->parse_data_uri($uri);
        my $decoded_img         = decode_base64($data);
        $tmpfile                = $self->write_data_uri_file($mime,$data);
    }
    else {
        $tmpfile     = $self->download_img_uri($uri);
    }
    
    if (! defined $tmpfile ) {
        $self->log->error("Unable to create tempfile from uri! $uri");
        return;
    }
    return $tmpfile;
}

sub is_data_uri ($self, $uri) {
    return $uri =~ m/^data:/;
}

sub parse_data_uri ($self, $uri) {
    my ($mime, $encoding, $data);
    if ( $uri =~ m/^data:(.*);(.*),(.*)$/) {
        $mime       = $1;
        $encoding   = $2;
        $data       = $3;
    }
    return $mime, $encoding, $data;
}

sub write_data_uri_file ($self, $mime, $data) {
    my ($type, $extension)  = split('/', $mime);
    # create a filename based on md5 hash, should have few collisions
    my $filename            = "/tmp/".md5_hex($data).".$extension"; 

    if ( $self->file_exists($filename) ) {
        return $filename;
    }
    return $self->create_file($filename, $data);
}

sub file_exists ($self, $filename) {
    return -e $filename;
}

sub create_file ($self, $filename, $data) {
    return try {
        open my $fh, ">", $filename or die $!;
        binmode $fh;
        print $fh $data;
        close $fh;
        return $filename;
    }
    catch {
        $self->log->error("Failed to write /tmp/$filename: $_");
        return undef;
    };
}

sub download_img_uri ($self, $uri) {
    my $request = HTTP::Request->new('GET', $uri);
    my $response= $self->ua->request($request);

    if ($response->is_success) {
        my $filename    = "/tmp/".(split('/',$uri))[-1];
        my $content     = $response->content;
        if ($content !~ /<html/) {
            return $self->create_file($filename, $content);
        }
        return undef;
    }
    # $self->log->error("Request to $uri failed: ",{filter => \&Dumper, value=>$response});
    $self->log->error("Request to $uri failed: ".$response->content);
    return undef;
}

sub move_file ($self, $old, $new) {
    my $err;
    my $opts    = {
        error   => \$err,
        mode    => 0755,
    };
    my $path = $self->get_path($new);
    make_path($path, $opts);
    move($old, $new);
}

sub get_path ($self, $fqn) {
    my @parts   = split('/', $fqn);
    pop @parts;
    return join('/',@parts);
}

sub build_new_name ($self, $id, $tmpfile) {
    my $basename = (split('/',$tmpfile))[-1];
    my $sysroot  = '/opt/scot/public/cached_images';
    my $year     = $self->get_entry_year($id);
    my $fqn      = join('/', $sysroot, $year, $id, $basename);
    return $fqn;
}

sub get_entry_year ($self, $id) {
    my $mongo   = $self->mongo;
    my $col     = $mongo->collection('Entry');
    my $obj     = $col->find_iid($id+0);
    if (! defined $obj ) {
        my $dt = DateTime->now;
        return $dt->year;
    }
    my $dt = DateTime->from_epoch(epoch => $obj->created);
    return $dt->year;
}

sub build_new_uri ($self, $fqn) {
    $fqn =~ m{/opt/scot/public(.*)$};
    return $1;
}

__PACKAGE__->meta->make_immutable;
1;

