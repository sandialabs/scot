package Scot::Flair::Io;

use Data::Dumper;
use DateTime;
use Try::Tiny;
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
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

has filemagic => (
    is          => 'ro',
    isa         => 'File::Magic',
    required    => 1,
    default     => sub { File::Magic->new(); } ,
);

sub get_object {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $mode    = $self->env->fetch_mode // 'mongo';

    return ($mode eq 'mongo') ? 
        $self->get_from_mongo($type, $id) :
        $self->get_via_api($type, $id);

}

sub get_from_mongo {
    my $self    = shift;
    my $colname = shift;
    my $id      = shift;
    my $log     = $self->env->log;

    $log->trace("get_from_mongo $colname $id");

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst($colname));

    my $object  = $col->find_iid($id);

    return $object;
}

sub get_via_api {
    my $self    = shift;
    my $colname = shift;
    my $id      = shift;
    my $uri     = "/scot/api/v2/$colname/$id";

    # TODO
    # get via the API
    # convert API return into object
    # return the object

}

sub get_alerts {
    my $self        = shift;
    my $alertgroup  = shift;
    my $agid        = $alertgroup->id;
    my $mode    = $self->env->fetch_mode // 'mongo';
    my @alerts  = ();
    my $log     = $self->env->log;

    if ( $mode eq "mongo" ) {
        my $col     = $self->env->mongo->collection('Alert');
        my $count   = $col->count({alertgroup => $agid});
        $log->debug("Found $count alerts as part of alertgroup $agid");
        my $cursor  = $col->find({ alertgroup => $agid });
        return  $cursor;
    }
    # TODO API fetch json array
    # turn into a "cursor"
    # return that cursor;
}

sub update_entry {
    my $self    = shift;
    my $entry   = shift;
    my $body    = shift;
    my $results = shift;
    my $log     = $self->env->log;
    my $mode    = $self->env->fetch_mode // 'mongo';

    $log->debug("update_entry(".$entry->id.")");

    my $update = {
        body        => $body,            # may have been updated my imgmunger
        body_plain  => $results->{text},
        body_flair  => $results->{flair},
    };

    if ( $mode eq "mongo" ) {
        $entry->update({
            '$set'  => $update
        });
        return;
    }
    # TODO API update
    $log->debug("need to implement api update");
}

sub update_entity {
    my $self    = shift;
    my $target  = shift;
    my $entity  = shift;
    my $log     = $self->env->log;
    my $mode    = $self->env->fetch_mode // 'mongo';

    $log->trace("Updating Entity ",{filter=>\&Dumper, value=>$entity});
    $log->trace("target is ", {filter=>\&Dumper, value=>$target});

    if ( $mode eq "mongo" ) {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection('Entity');
        $col->update_entity($target, $entity);
        return;
    }
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
            $log->debug("EntityType ".$et->id." length less than 3 chars (".
                        $et->match.").  Skipping.");
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

sub get_entity_id {
    my $self    = shift;
    my $entity  = shift;
    my $log     = $self->env->log;
    my $query   = { value => $entity->{value} };
    $log->trace("Looking for entity matching ", {filter=>\&Dumper, value => $query});
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entity');
    my $obj     = $col->find_one($query);
    if (defined $obj) {
        return $obj->id;
    }
    $log->debug("error: no matching entity");
    return undef;
}

sub update_entities {
    my $self    = shift;
    my $target  = shift;
    my $results = shift;
    my $mongo   = $self->env->mongo;
    my $ecol    = $mongo->collection('Entity');
    my $log     = $self->env->log;

    $log->debug("updating entities");

    my $entities    = $results->{entities};

    foreach my $entity_href (@$entities) {
        my $query   = { 
            type => $entity_href->{type}, 
            value => $entity_href->{value} };
        my $status = $ecol->update_entity($target, $entity_href);
    }

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

sub send_mq {
    my $self    = shift;
    my $queue   = shift;
    my $data    = shift;
    my $mq      = $self->env->mq;

    $mq->send($queue, $data);
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

sub send_update_notices {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;

    if ( $type eq "entity" ) {
        $self->send_entity_notice($id);
    }
    else {
        $self->send_other_notice($type, $id);
    }
}

sub send_entity_notice {
    my $self    = shift;
    my $value   = shift;
    my $mode    = $self->env->fetch_mode // 'mongo';
    my $log     = $self->env->log;

    if ( $mode eq "mongo" ) {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection('Entity');
        my $obj     = $col->get_by_value($value);
        if ( ! defined $obj ) {
            $log->error("Entity $value NOT FOUND!");
            return;
        }
        my $enrich_message = {
            action  => 'created',
            data    => {
                type    => 'entity',
                id      => $obj->id,
            }
        };
        $self->send_mq("/queue/enricher", $enrich_message);
        return;
    }
    $log->logdie("api fetch of entity in send entity notice not implemented yet");
} 

sub send_other_notice {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->env->log;

    my $message = {
        action  => 'updated',
        data    => {
            type    => $type,
            id      => $id,
        }
    };
    $self->send_mq("/topic/scot", $message);
}

sub update_alert {
    my $self    = shift;
    my $id      = shift;
    my $results = shift;

    return ($self->env->fetch_mode eq 'mongo') ? 
        $self->update_alert_via_mongo( $id, $results) :
        $self->update_alert_via_api( $id, $results);
}

sub update_alert_via_mongo {
    my $self    = shift;
    my $id      = shift;
    my $results = shift;
    my $edb     = $results->{entities};
    my $log     = $self->env->log;

    my $update  = {
        '$set'  => {
            parsed  => 1,
        }
    };

    $log->trace("update_alert $id edb: ", {filter => \&Dumper, value=>$edb});
    $log->trace("update_alert $id results: ", {filter => \&Dumper, value=>$results});

    foreach my $column (keys %{$results->{$id}}) {
        next if $column eq 'entities';
        $update->{'$set'}->{data_with_flair}->{$column} = 
            $results->{$id}->{$column}->{flair};
    }

    $log->trace("Alert Update for $id = ",{filter=>\&Dumper, value => $update});

    my $alert   = $self->get_object('alert', $id);

    try {
        $alert->update($update);
    }
    catch {
        $log->error("Failed to upated Alert $id: $_");
    };

    $self->link_alert_entities($alert, $edb);

    # send mq 
    my $message = {
        action  => 'updated',
        data    => {
            type    => 'alert',
            id      => $id,
        }
    };
    $self->send_mq("/topic/scot", $message);

}

sub update_alertgroup {
    my $self    = shift;
    my $id      = shift;
    my $edb     = shift;
    return ($self->env->fetch_mode eq 'mongo') ? 
        $self->update_alertgroup_via_mongo( $id, $edb):
        $self->update_alertgroup_via_api( $id, $edb);
}

sub update_alertgroup_via_mongo {
    my $self    = shift;
    my $id      = shift;
    my $edb     = shift;
    my $log     = $self->env->log;
    my $ag      = $self->get_object('alertgroup', $id);
    my $update  = {
        '$set'  => {
            parsed  => 1,
        }
    };

    try {
        $ag->update($update);
    }
    catch {
        $log->error("Failed to update Alertgroup $id: $_");
    };
    my $message = {
        action  => 'updated',
        data    => {
            type    => 'alertgroup',
            id      => $id,
        }
    };
    $self->link_alertgroup_entities($ag,$edb);
    $self->send_mq("/topic/scot", $message);
}

sub link_alert_entities {
    my $self    = shift;
    my $alert   = shift;
    my $edb     = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    $log->trace("link_alert_entities was passed edb of ",
                { filter => \&Dumper, value => $edb });

    foreach my $type (keys %$edb) {
        foreach my $value (keys %{$edb->{$type}}) {
            $self->link_via_mongo(
                $alert->id, 'alert',
                $type, $value,
            );
        }
    }
}

sub link_alertgroup_entities {
    my $self    = shift;
    my $ag      = shift;
    my $edb     = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    foreach my $type (keys %$edb) {
        foreach my $value (keys %{$edb->{$type}}) {
            $self->link_via_mongo(
                $ag->id, 'alertgroup',
                $type, $value,
            );
        }
    }
}

sub link_via_mongo {
    my $self    = shift;
    my $id      = shift;
    my $otype   = shift;
    my $etype   = shift;
    my $evalue  = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    my $entity = $self->get_entity($etype,$evalue);
    my $obj    = $self->get_object($otype, $id);

    try {
        $mongo->collection('Link')->link_objects($obj, $entity);
    }
    catch {
        $log->error("Failed to Link $otype $id to $etype $evalue");
    };
}

sub get_entity {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;
    my $entity;

    $log->trace("get_entity $type $value");

    while ( ! defined $entity ) {
        $entity  = try {
            $mongo->collection('Entity')->get_by_value($value);
        }
        catch {
            $log->error("Failed to entity by value $value");
        };

        $log->trace("entity = ",{filter=>\&Dumper, value => $entity});

        if ( ! defined $entity ) {
            $log->error("Entity not found! Creating...");
            $entity = $self->create_entity($type, $value);
        }

        if ( $entity->type ne $type ) {
            $log->error("whoops, looking for $type entity but got ".$entity->type);
            $entity = undef;
        }
    }
    $log->trace("got entity ".$entity->value);
    return $entity;
}

sub create_entity {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    my $href    = {
        type    => $type,
        value   => $value,
    };

    my $entity = try {
        $mongo->collection('Entity')->create($href);
    }
    catch {
        $log->error("Failed to create Entity: $_, ",{filter=>\&Dumper, value=>$href});
    };

    return $entity;
}

    
sub update_remoteflair {
    my $self    = shift;
    my $rfobj   = shift;
    my $results = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;

    my $entities    = $self->xform_entities($results->{entities});

    my $update  = {
        '$set'  => {
            results => {
                entities    => $entities,
                flair       => $results->{flair},
                text        => $results->{text},
            },
            status  => 'ready',
        }
    };

    try {
        $rfobj->update($update);
    }
    catch {
        $log->error("Failed to update Remoteflair ".$rfobj->id.": $_");
    };
}

sub xform_entities {
    my $self    = shift;
    my $href    = shift;
    my @entities    = ();

    foreach my $type (keys %$href) {
        foreach my $value (keys %{$href->{$type}}) {
            push @entities, {
                type    => $type,
                value   => $value,
            };
        }
    }
    return wantarray ? @entities : \@entities;
}


1;
