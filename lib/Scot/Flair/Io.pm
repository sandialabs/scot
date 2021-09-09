package Scot::Flair::Io;

use Try::Tiny;
use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use File::Slurp;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);
use namespace::autoclean;
use MIME::Base64;
use File::Magic;
use File::Copy;
use Moose;

has env => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required=> 1,
);

has filemagic => (
    is      => 'ro',
    isa     => 'File::Magic',
    required=> 1,
    default => sub { File::Magic->new(); },
);

sub get_object {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;

    $log->debug("Retrieving $type $id object");

    my $colname     = ucfirst($type);
    my $collection  = $mongo->collection($colname);

    my $object  = try {
        $collection->find_iid($id);
    }
    catch {
        $log->error("Error finding $type $id: $_");
    };

    if ( ! defined $object ) {
        $log->error("$type $id object not found!");
    }
    return $object
}

sub get_alerts {
    my $self    = shift;
    my $agobj   = shift;
    my $agid    = $agobj->id;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my @alerts  = ();

    my $query   = { alertgroup => $agid };
    my $col     = $mongo->collection('Alert');
    my $count   = $col->count($query);
    my $cursor  = $col->find($query);

    $log->debug("Found $count alerts in Alertgroup $agid");
    return $cursor;
}

sub get_entity {
    my $self    = shift;
    my $href    = shift; # { type => t, value => v }
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $type    = $href->{type};
    my $value   = $href->{value};
    $log->debug("Retrieving for $type $value entity");

    my $col     = $mongo->collection('Entity');
    my $entity  = try {
        $col->find_one($href);
    }
    catch {
        $log->error("Error finding entity $type $value");
    };

    if ( ! defined $entity ) {
        $log->debug("$type $value entity did not exist, creating");
        $entity = $self->create_entity($type, $value);
    }
    return $entity;
}

sub create_entity {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $data    = { type => $type, value => $value };
    my $entity  = try {
        $mongo->collection('Entity')->create($data);
    }
    catch {
        $log->error("Failed to create new Entity $type $value: $_");
    };
    return $entity;
}

sub get_entity_id {
    my $self    = shift;
    my $href    = shift;

    my $entity  = $self->get_entity($href);
    return $entity->id;
}

sub update_alert {
    my $self    = shift;
    my $alertid = shift;
    my $results = shift;
    my $edb     = $results->{$alertid}->{entities};
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("updating alert $alertid");
    $log->trace("EDB = ",{filter=>\&Dumper, value=>$edb});

    my $data  = { parsed => 1 };

    foreach my $column (keys %{$results->{$alertid}}) {
        next if $column eq "entities";
        $data->{data_with_flair}->{$column} = $results->{$alertid}->{$column}->{flair};
    }

    my $update  = { '$set' => $data };
    my $alert   = $self->get_object('alert', $alertid);

    try { $alert->update($update) }
    catch { $log->error("Failed to update Alert $alertid"); };

    $self->link_entities($alert, $edb);
    $self->send_entities_to_enricher($edb);
    $self->send_alert_updated_message($alertid);
}

sub send_entities_to_enricher {
    my $self    = shift;
    my $edb     = shift;
    my $log     = $self->env->log;
    my $msg     = {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'entity',
        }
    };

    $log->debug("Attempting to enrich edb: ");
    $log->trace({filter=>\&Dumper, value=>$edb});

    foreach my $type (keys %$edb) {
        foreach my $value (keys %{$edb->{$type}}) {
            my $entity  = $self->get_entity({type => $type, value => $value});
            $msg->{data}->{id} = $entity->id;
            $self->send_mq('/queue/enricher', $msg);
        }
    }
}

sub send_alert_updated_message {
    my $self    = shift;
    my $aid     = shift;
    my $msg     = {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'alert',
            id      => $aid,
        }
    };
    $self->send_mq('/topic/scot', $msg);
}

sub update_alertgroup {
    my $self    = shift;
    my $agid    = shift;
    my $edb     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("updating alertgroup $agid");

    my $update  = {'$set' => { parsed => 1 }};
    my $alertgroup  = $self->get_object('alertgroup', $agid);

    try { $alertgroup->update($update); }
    catch { $log->error("Failed to update Alertgroup $agid") };

    $self->link_entities($alertgroup, $edb);
    #  no need to send entities to enrich as it is done with each alert
    $self->send_alertgroup_updated_message($agid);
}

sub send_alertgroup_updated_message {
    my $self    = shift;
    my $agid    = shift;
    my $msg     = {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'alertgroup',
            id      => $agid,
        }
    };
    $self->send_mq('/topic/scot', $msg);
}

sub update_remoteflair {
    my $self    = shift;
    my $rfobj   = shift;
    my $results = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $entities = $self->transform_entities($results->{entities});
    my $update   = {
        results => {
            entities    => $entities,
            flair       => $results->{flair},
            text        => $results->{text},
        },
        status  => 'ready',
    };

    try { $rfobj->update({ '$set' => $update }); }
    catch { $log->error("Failed to update Remoteflair $rfobj->id: $_"); };
}

sub transform_entities {
    my $self    = shift;
    my $href    = shift;
    my @entities    = ();

    foreach my $type (keys %$href) {
        foreach my $value (keys %{$href->{$type}}) {
            push @entities, { type => $type, value => $value };
        }
    }
    return wantarray ? @entities : \@entities;
}


sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $body    = shift;
    my $results = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->debug("update entry ".$entry->id);

    my $update  = {
        parsed      => 1,
        body        => $body,
        body_plain  => $results->{text},
        body_flair  => $results->{flair},
    };

    try { $entry->update({ '$set' => $update }) }
    catch { $log->error("Failed to update entry $entry->id: $_"); };

    $self->send_entities_to_enricher($results->{entities});
    $self->send_entry_updated_messages($entry);
    $self->link_entities($entry, $results->{entities});
}

sub link_entities {
    my $self    = shift;
    my $obj     = shift;
    my $objtype = (split(/::/,ref($obj)))[-1];
    my $edb     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Link');

    $log->debug("linking Entities and $objtype");

    my $target; # will only be defined if an entry
    if ( $objtype eq "Entry") {
        $target = $obj->target;
    }

    foreach my $type (keys %$edb) {
        foreach my $value (keys %{$edb->{$type}}) {
            my $entity  = $self->get_entity({type => $type, value => $value});

            my $estatus = $entity->status;

            next if ( defined $estatus and $estatus eq "untracked");

            my $link = $self->link_objects($obj, $entity);

            if ( defined $target ) {
                $log->trace("Linking Entry Target to Entity");
                my $secondlink = $self->link_target($entity, $target);
            }
        }
    }
}

sub link_objects {
    my $self    = shift;
    my $obj1    = shift;
    my $obj2    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Link');
    my $link = try {
        $col->link_objects($obj1, $obj2);
    }
    catch {
        my $type1 = ref($obj1);
        my $type2 = ref($obj2);
        $log->error("Failed to create Link between $type1 $obj1->id and $type2 $obj2->id");
    };
    return $link;
}

sub link_target {
    my $self    = shift;
    my $obj1    = shift;
    my $target  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $col     = $mongo->collection('Link');

    my $obj2    = $self->get_object($target->{type}, $target->{id});
    if (defined $obj2 ) {
        my $seclink = try {
            $col->link_objects($obj1, $obj2);
        }
        catch {
            my $type1 = ref($obj1);
            my $type2 = ref($obj2);
            $log->error("Failed to create secondary link between $type1 $obj1->id and $type2 $obj2->id");
        };
        return $seclink;
    }
    else {
        $log->error("Unable to find secondary target $target->{type} $target->{id}");
    }
    return undef;
}

sub send_entry_updated_messages {
    my $self    = shift;
    my $entry   = shift;
    my $eid     = $entry->id;
    my $target  = $entry->target;
    my $msg     = {
        action  => 'updated',
        data    => {
            who     => 'scot-flair',
            type    => 'entry',
            id      => $eid,
        }
    };
    $self->send_mq('/topic/scot', $msg);
    $msg->{data}->{type} = $target->{type};
    $msg->{data}->{id}   = $target->{id};
    $self->send_mq('/topic/scot', $msg);
}

sub send_mq {
    my $self    = shift;
    my $queue   = shift;
    my $data    = shift;
    my $mq      = $self->env->mq;
    my $log     = $self->env->log;

    $log->trace("Sending to $queue : ");
    $log->trace({filter=>\&Dumper, value => $data});

    $mq->send($queue, $data);
}

sub get_single_word_regexes {
    my $self    = shift;
    my $query   = { options => { multiword => "no" } };
    my @ets     = $self->get_entity_types($query);
    return wantarray ? @ets : \@ets;
}


sub get_multi_word_regexes {
    my $self    = shift;
    my $query   = { options => { multiword => "yes" } };
    my @ets     = $self->get_entity_types($query);
    return wantarray ? @ets : \@ets;
}
    
sub get_entity_types {
    my $self    = shift;
    my $query   = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entitytype');
    my $cursor  = $col->find($query);
    my @etypes  = ();
    my $log     = $self->env->log;

    $self->env->log->trace('get_entity_types');

    while (my $et = $cursor->next) {
        if ( length($et->match) < 3 ) {
            # causes crashes due to unicode in et->match.  Can scrub it
            # but this really isn't needed for now
            # $log->debug("EntityType ".$et->id." length less than 3 chars (".
            #             $et->match.").  Skipping.");
            next;
        }
        $self->env->log->trace("adding type ".$et->value);
        push @etypes, {
            type    => $et->value,
            regex   => $et->match,
            order   => $et->order,
            options => $et->options,
        };
    }
    return wantarray ? @etypes : \@etypes;
}

sub save_data_uri {
    my $self        = shift;
    my $link        = shift;
    my $entry_id    = shift;
    my $log         = $self->env->log;

    $log->debug("save_data_uri");

    my ($mimetype, $encoding, $data) = $self->parse_uri($link);

    $log->debug("Extracting $mimetype ($encoding)");

    my ($type, $ext)  = split('/', $mimetype);
    my $decoded       = decode_base64($data);
    my $md5           = md5_hex($decoded);
    my ($fqn, $fname) = $self->create_file($entry_id, $md5.".".$ext, $decoded);
    return $fqn, $fname;
}

sub parse_uri {
    my $self    = shift;
    my $link    = shift;
    my ($mimetype, $encoding, $data); 
    if ($link =~ m/^data:(.*);(.*),(.*)$/) {
        $mimetype = $1;
        $encoding = $2;
        $data     = $3;
    }
    $self->env->log->debug("parse URI: $mimetype, $encoding, data");
    return $mimetype, $encoding, $data;
}


sub download {
    my $self    = shift;
    my $link    = shift;
    my $entry_id  = shift;
    my $agent   = $self->create_web_agent;
    my $request = $self->create_request($link);
    return $self->do_download($agent, $request, $link, $entry_id);
}

sub create_web_agent {
    my $self    = shift;
    my $env     = $self->env;
    my $conf    = $env->lwp;

    my $agent   = LWP::UserAgent->new(
        env_proxy   => $conf->{use_proxy},
        timeout     => $conf->{timeout},
    );
    $agent->ssl_opts(
        SSL_verify_mode => $conf->{ssl_verify_mode},
        verify_hostname => $conf->{verify_hostname},
        SSL_ca_path     => $conf->{ssl_ca_path},
    );
    $agent->proxy( 
        $conf->{proxy_protocols}, 
        $conf->{proxy_uri},
    );
    $agent->agent($conf->{lwp_ua_string});
    return $agent;
}

sub create_request {
    my $self    = shift;
    my $link    = shift;
    my $request = HTTP::Request->new('GET', $link);
    return $request;
}

sub do_download {
    my $self    = shift;
    my $agent   = shift;
    my $request = shift;
    my $link    = shift;
    my $entry_id    = shift;
    my $log     = $self->env->log;

    my $response    = $agent->request($request);

    if ( $response->is_success ) {
        my $filename = (split('/', $link))[-1];
        my $content  = $response->content;
        my ($fqn, $fname, $orig) = $self->create_file($entry_id, $filename, $content);
        return $fqn, $fname, $orig;
    }

    $log->error("Failed to download image $link: ".$response->status_line);
    return undef, undef, undef;
}

sub create_file {
    my $self        = shift;
    my $entry_id    = shift;
    my $name        = shift;
    my $data        = shift;
    my $env         = $self->env;
    $name           =~ s/\?.*$//g;
    my $store_dir   = $env->img_dir;
    my $log         = $self->env->log;

    # need to create subdir based on some criteria
    $log->debug("Creating file for entry $entry_id name = $name");
    
    my ($base, $extension) = $self->get_base_ext($name);

    $log->debug("base = $base extension = $extension");

    my $md5         = md5_hex($data);
    my $newname     = join('.', $md5 , $extension);
    my $fqn = $self->create_fqn($store_dir, $entry_id, $newname);
    $self->write_img_file($fqn, $data);

    # sometimes fqn does not have a extention
    # fix it up, if possible
    $fqn = $self->validate_fqn($fqn);
    return $fqn, $newname, $name;
}

sub validate_fqn {
    my $self    = shift;
    my $fqn     = shift;
    my $magic   = $self->filemagic;
    my $log     = $self->env->log;

    $log->trace("Validating $fqn");

    if ( $fqn =~ /\.$/ ) { # name ends in dot
        my $newfqn = '';
        $log->debug("FQN is $fqn and ends in dot");
        my $filetype = $magic->type($fqn);
        $log->debug("Magic things file is of type $filetype");
        if ( $filetype =~ /GIF/i ) {
            $newfqn = $fqn . 'gif';
        }
        elsif ( $filetype =~ /PNG/i ) {
            $newfqn = $fqn. 'png';
        }
        elsif ( $filetype =~ /JPEG/i ) {
            $newfqn = $fqn. 'jpg';
        }
        elsif ( $filetype =~ /PDF/i ) {
            $newfqn = $fqn. 'pdf';
        }
        else {
            $newfqn = substr $fqn, 0, -1;
        }
        if ( $newfqn ne $fqn ) {
            $self->move_file($fqn, $newfqn);
        }
        return $newfqn;
    }
    # accept what is there
    return $fqn;
}

sub move_file {
    my $self    = shift;
    my $src     = shift;
    my $dst     = shift;
    move($src, $dst);
}

sub create_fqn {
    my $self        = shift;
    my $store_root  = shift;
    my $id          = shift;
    my $newname     = shift;
    my $log         = $self->env->log;
    my $year    = $self->get_target_year($id);
    # making the directory structure deeper because it can be difficult
    # to work with directories with thousands of files in it.
    # note: $year may be undef in weird failure cases and that is ok
    # we will just have a structure like:
    # /opt/scot/public/cached_images
    #      /entry
    #          /123
    #      /2021
    #          /entry
    #             /124
    my @parts   = ($store_root);
    push @parts, $year if defined $year;
    push @parts, 'entry', $id, $newname;
    my $fqn     = join('/',@parts);
    $log->debug("created fqn or $fqn");
    return $fqn;
}

sub get_target_year {
    my $self    = shift;
    my $id      = shift;
    # think about finding the target of the entry and creating the year 
    # based on that date
    my $entry   = $self->get_object('entry',$id);
    return undef unless (defined $entry);
    # but! who really cares, lets just use the creation date for the entry
    # to get the year;
    my $dt = DateTime->from_epoch(epoch => $entry->created);
    return $dt->year;
}

sub basename {
    my $self    = shift;
    my $fqn     = shift;
    my @parts = split(/\//, $fqn);
    my $name  = pop @parts;
    my $path  = join('/',@parts);
    return $path, $name;
}


sub write_img_file {
    my $self    = shift;
    my $fqn     = shift;
    my $data    = shift;

    my ($path, $name) = $self->basename($fqn);
    
    if ( ! -d $path ) {
        $self->create_dir($path);
    }

    if ( $self->file_exists($fqn) ) {
        if ( $self->is_file_same($fqn, $data) ) {
            return;
        }
        else {
            $fqn = $self->make_unique_name($fqn);
        }
    }

    try {
        open my $fh, ">", "$fqn" or die $!;
        binmode $fh;
        print $fh $data;
        close $fh;
    }
    catch {
        $self->env->log->error("Failed to write $fqn: $_");
    };

  
}

sub create_dir {
    my $self     = shift;
    my $path    = shift;
    my $log     = $self->env->log;
    my $err;
    my $opts    = {
        error   => \$err,
        mode    => 0775,
    };
    make_path($path, $opts);

    if ( defined $err && @$err ) {
        for my $diag (@$err) {
            my ($file, $message) = %$diag;
            if ( $file eq '') {
                $log->error("general make_path error: $message");
            }
            else {
                $log->error("failed make_path($file): $message");
            }
        }
    }
}

sub file_exists {
    my $self    = shift;
    my $fqn     = shift;
    return -e $fqn;
}

sub is_file_same {
    my $self    = shift;
    my $fqn     = shift;
    my $data    = shift;
    my $filedata = read_file($fqn);
    my $existinghash    = md5_hex($filedata);
    my $newhash         = md5_hex($data);

    if ( $existinghash eq $newhash ) {
        return 1;
    }
    return undef;
}

sub get_base_ext {
    my $self    = shift;
    my $name    = shift;
    my @parts   = split(/\./, $name);
    my $ext;
    my $log     = $self->env->log;

    $log->trace("$name Parts = ".join('  ',@parts));

    if ( $parts[-1] eq join('', @parts) ){
        # no extension
        $ext = undef;
    }
    else {
        $ext     = pop @parts;
    }
    my $base    = join('.', @parts);
    return $base, $ext;
}

sub make_unique_name {
    my $self    = shift;
    my $fqn     = shift;
    my ($path, $name) = $self->basename($fqn);
    my ($base, $ext)  = $self->get_base_ext($name);

    $base .= time();
    my $newname = join('.', $base, $ext);
    my $newfqn  = join('/', $path, $newname);
    return $newfqn;
}

sub put_stat {
    my $self    = shift;
    my $metric  = shift;
    my $value   = shift;
    my $now     = DateTime->now;
    my $mode    = $self->env->fetch_mode // 'mongo';
    my $log     = $self->env->log;

    if ( $mode eq "mongo" ) {
        try {
            my $mongo   = $self->env->mongo;
            my $col     = $mongo->collection('Stat');
            $col->increment($now, $metric, $value);
        }
        catch {
            $self->log->warn("Caught error: $_");
            $self->log->warn("Attempt to write stat may have failed");
        };
    }
    else {
        $log->error("put_stat has not implemented API update");
    }
}

sub update_entry_body {
    my $self    = shift;
    my $entry   = shift;
    my $body    = shift;

    $entry->update_set({
        '$set'  => { body => $body }
    });
}

sub create_child_entry {
    my $self    = shift;
    my $entry   = shift;
    my $part    = shift;

    my $json    = $entry->as_hash;

    delete $json->{id};
    delete $json->{body_flair};
    delete $json->{body_plain};
    $json->{body}   = $part;
    $json->{parent} = $entry->id;

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entry');
    my $newentry   = $col->create($json);

    return $newentry;
}
1;
