package Scot::Imgmunger::Io;

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

sub retrieve_item {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst($type));
    my $item    = $col->find_iid($id);
    return $item;
}

sub update_item {
    my $self    = shift;
    my $item    = shift;
    my $html    = shift;
    
    $item->update({
        '$set' => {
            body_flair => $html,
            updated    => time(),
        }
    });

}

sub save_data_uri {
    my $self        = shift;
    my $link        = shift;
    my $entry_id    = shift;
    my $log         = $self->env->log;

    my ($mimetype, $encoding, $data) = $self->parse_uri($link);

    $log->trace("Extracting $mimetype ($encoding)");

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
    if ($link =~ m/src="data:(.*);(.*),(.*)$/) {
        $mimetype = $1;
        $encoding = $2;
        $data     = $3;
    }
    $self->env->log->trace("parse URI: $mimetype, $encoding, data");
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
    my $self    = shift;
    my $entry_id    = shift;
    my $name    = shift;
    my $data    = shift;
    my $env     = $self->env;
    $name =~ s/\?.*$//g;
    my $store_dir   = $env->img_dir;

    # need to create subdir based on some criteria
    
    my ($base, $extension) = $self->get_base_ext($name);

    my $md5 = md5_hex($data);
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
    return $fqn;
}

sub get_target_year {
    my $self    = shift;
    my $id      = shift;
    # think about finding the target of the entry and creating the year 
    # based on that date
    my $entry   = $self->retrieve_item('entry',$id);
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



    




1;
