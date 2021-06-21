package Scot::Flair::Io;

use Data::Dumper;
use Try::Tiny;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use File::Slurp;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);
use namespace::autoclean;
use MIME::Base64;
use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
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

    $log->debug("get_from_mongo $colname $id");

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

    if ( $mode eq "mongo" ) {
        my $col     = $self->env->mongo->collection('Alert');
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

    $log->debug("Updating Entity ",{filter=>\&Dumper, value=>$entity});
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

    $self->env->log->trace('get_entity_types');

    while (my $et = $cursor->next) {
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
    my $query   = { value => $entity->{value} };
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection('Entity');
    my $obj     = $col->find_one($query);
    if (defined $obj) {
        return $obj->id;
    }
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
    return $fqn, $newname, $name;
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

    

1;
