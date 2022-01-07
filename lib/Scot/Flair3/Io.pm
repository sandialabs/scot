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
use Log::Log4perl;
use Meerkat;

has queue   => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => '/queue/flair',
);

has topic   => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => '/topic/flair',
);

has logfile => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '/var/log/scot/flair.log',
);

has loglevel => ( 
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'DEBUG',
);

has log => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    required=> 1,
    lazy    => 1,
    builder => '_build_log',
);

sub _build_log ($self) {
    return Log::Log4perl->get_logger('FlairLog');
}

has mongo   => (
    is      => 'ro',
    isa     => 'Meerkat',
    required=> 1,
    builder => '_build_mongo',
);

has dbname  => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => 'scot-prod',
);

sub _build_mongo ($self) {
    return Meerkat->new(
        model_namespace         => 'Scot::Model',
        collection_namespace    => 'Scot::Collection',
        database_name           => $self->dbname,
        client_options          => {
            host        => 'mongodb://localhost',
            w           => 1,
            find_master => 1,
            socket_timeout_ms => 600000,
        }
    );
}

has stomp  => (
    is      => 'ro',
    isa     => 'Scot::Flair3::Stomp',
    required=> 1,
);

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

sub get_timer ($self)  {
    my $start   = [ gettimeofday ];
    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [ gettimeofday ]);
        return $elapsed;
    };
}

sub clear_worker_status {
    return;
}

sub send_mq ($self, $dest, $href) {
    $self->stomp->send($dest, $href);
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

sub update_remote_flair ($self, $update) {
    my $rf      = $update->{remoteflair};
    my $edb     = $update->{edb};
    my $flair   = $update->{flair};
    my $text    = $update->{text};

    my $mongo_update    = {
        '$set'  => {
            status      => 'ready',
            results     => {
                edb     => $edb,
            }
        }
    };
    try { $rf->update($mongo_update) }
    catch {
        $self->log->error("Failed to update RF ".$rf->id.": $_");
    };
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
    my $data    = $message->{body}->{data};
    my $type    = $data->{type};
    my $id      = $data->{id} + 0;
    my $col     = $self->mongo->collection(ucfirst($type));
    my $obj     = $col->find_iid($id);
    $self->log->debug("Retrieved $type $id");
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

sub update_alertgroup ($self, $alertgroup, $edb,) {
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
    my $log     = $self->log;
    my $alert   = $update->{alert};
    my $flair   = $update->{flair};
    my $text    = $update->{text};
    my $edb     = $update->{edb};
    my $id      = $alert->id;
    my $dflair  = {};
    my $timer   = $self->get_timer;

    foreach my $key (keys %$flair) {
        $dflair->{$key} = $flair->{$key};
    }

    my $mongo_update  = { 
        '$set'  => {
            parsed => 1, 
            data_with_flair => $dflair,
        }
    };
    $log->trace("Attempting update of alert $id with ",{filter=>\&Dumper, value=> $mongo_update});

    $alert->update($mongo_update);
    $log->debug("TIME: mongo update of alert => ".&$timer." seconds");
    $timer  = $self->get_timer;
    $self->link_entities($alert, $edb);
    $log->debug("TIME: link_entities => ".&$timer." seconds");
    $timer  = $self->get_timer;
    $self->send_alert_update_message($alert);
    $log->debug("TIME: send_alert_update_message => ".&$timer." seconds");
}

sub send_alert_update_message ($self, $alert) {
    my $log = $self->log;
    my $id  = $alert->id;
    $self->send_mq('/topic/scot', {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'alert',
            id      => $id,
        }
    });
    $log->trace("Sent Alert $id updated message to /topic/scot");
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
    my $count   = 0;
    foreach my $type (keys %$entities) {
        foreach my $value (keys %{$entities->{$type}}) {
            my $entity = $self->get_entity($type,$value);
            $msg->{data}->{id} = $entity->id;
            $self->send_mq('/queue/enricher', $msg);
            $count++;
        }
    }
    $self->log->debug("Sent $count entities to /queue/enricher");
}

sub get_entity ($self, $type, $value) {
    my $col     = $self->mongo->collection('Entity');
    my $obj     = $col->find_one({type => $type, value => $value});
    if ( ! defined $obj ) {
        $self->log->trace("Entity $type $value not found, creating...");
        $obj = $col->create({ type => $type, value=> $value});
    }
    return $obj;
}

sub send_entry_updated_messages ($self, $entry) {
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
    $self->log->debug("Sent Entry $id update message to /topic/scot");

    my $type    = $target->{type};
    my $tid      = $target->{id};

    $msg->{data}->{type}    = $type;
    $msg->{data}->{id}      = $tid;
    $self->send_mq('/topic/scot', $msg);
    $self->log->debug("Sent $type $tid update message to /topic/scot");
}

sub link_entities ($self, $obj, $edb) {
    my $log         = $self->log;
    my $obj_type    = $self->get_object_type($obj);
    my $target;
    if ( $obj_type eq "Entry") {
        $target = $obj->target;
    }

    my $entities    = $edb->{entities};

    $log->trace("EDB = ",{filter=>\&Dumper, value => $entities});

    TYPE:
    foreach my $type (keys %$entities) {
        ENTITY:
        foreach my $value (keys %{$entities->{$type}}) {
            my $entity = $self->get_entity($type, $value);

            if ( ! defined $entity ) {
                $entity = $self->create_entity($type, $value);
            }

            my $status = $entity->status;

            $log->trace("LINK: Entity $type $value (".$entity->id.") status $status");

            next ENTITY if (defined $status and $status eq "untracked");

            my $link   = $self->link_objects($obj, $entity);
            if ( defined $target ) {
                my $tobj    = $self->get_target_obj($target);
                if ( defined $tobj ) {
                    my $slink = $self->link_objects($entity, $tobj);
                }
            }
        }
    }
}

sub get_target_obj ($self, $target) {
    my $type    = $target->{type};
    my $id      = $target->{id};
    my $col     = $self->mongo->collection(ucfirst($type));
    my $obj     = $col->find_iid($id);
    return $obj;
}

sub create_entity ($self, $type, $value) {
    my $log     = $self->log;
    my $data    = { type => $type, value => $value };
    my $col     = $self->mongo->collection('Entity');
    $log->debug("creating entity ",{filter=>\&Dumper, value=>$data});
    my $entity  = $col->create($data);
    if (! defined $entity and ref($entity) ne 'Scot::Model::Entity') {
        $log->error("FAILED TO CREATE ENTITY!");
    }
    return $entity;
}

sub link_objects ($self, $o1, $o2) {
    my $log     = $self->log;
    my $dm      = sprintf("%s[%d] to %s[%d]",ref($o1),$o1->id,ref($o2),$o2->id);
    my $col     = $self->mongo->collection('Link');
    my $link    = try {
        $col->link_objects($o1, $o2);
        $self->log->trace("Linked $dm");
    }
    catch {
        $self->log->error("Failed to create Link $dm");
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
    my $log     = $self->log;
    my $newuri  = '';
    my $tmpfile; 

    if ($self->is_data_uri($uri)) {
        my ($mime, $enc, $data) = $self->parse_data_uri($uri);
        my $decoded_img         = decode_base64($data);
        $tmpfile                = $self->write_data_uri_file($mime,$data);
        $log->debug("wrote data uri to $tmpfile");
    }
    else {
        $tmpfile     = $self->download_img_uri($uri);
        $log->debug("downloaded uri to $tmpfile");
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


sub download_img_uri_lwp ($self, $uri) {
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

