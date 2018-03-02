package Scot::Controller::File;

=head1 Name

Scot::Controller::File;

=head1 Description

Handle all the API interactions with uploading/downloading files into SCOT

=cut

use Data::Dumper;
use Try::Tiny;
use File::Path qw(make_path);
use File::Slurp;
use File::Type;
use Mojo::Asset::File;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex sha256_hex);
use Mojo::JSON qw(decode_json encode_json);
use MIME::Base64;

use strict;
use warnings;
use base 'Mojolicious::Controller';

sub put_stat {
    my $self    = shift;
    my $metric  = shift;
    my $value   = shift;
    my $env     = $self->env;
    my $nowdt   = DateTime->from_epoch( epoch => $env->now );
    my $col     = $env->mongo->collection('Stat');
    $col->increment($nowdt, $metric, $value);
}

sub upload {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $status  = {};
    my @statuses    = ();

    $log->debug("Processing Uploaded File(s)");

    my @uploads = $self->req->upload('upload');
    my $user    = $self->session('user');
    
    # must have an "entry_id" or a target_type/target_id combo
    # entry_id trumps

    my ($entry_id, $target_type, $target_id) = $self->get_targets;

    unless ( defined ($entry_id) ) {
        $entry_id = 0; # this will be the parent of the new entry
    }

    my ($group_href,$year) = 
        $self->get_groups_and_year($target_type, $target_id);

    UPLOAD:
    foreach my $upload (@uploads) {
        my $size    = $upload->size;
        my $name    = $upload->filename;
        my $dir     = join('/',
                           $env->file_store_root,
                           $year,
                           $target_type,
                           $target_id);
        
        my $err;
        my %opts = (
            error   => \$err,
            mode    => 0775,
        );
        unless ( -d $dir ) {
            make_path($dir, \%opts);
        }
        if ( @$err ) {
            for my $diag (@$err) {
                my ($file, $message) = %$diag;
                if ( $file eq '') {
                    $log->error("general make_path error: $message");
                }
                else {
                    $log->error("problem make_path($file): $message");
                }
            }
        }


        my $fqn = $dir . '/' . $name;
        if ( -e $fqn ) {
            $fqn .= ".".time();
        }

        $log->debug("Moving $name to $fqn");

        $upload = $upload->move_to($fqn);

        if ( $! ) {
            $log->error("Failed to Move: $!");
            $status = { 
                status  => 'failed',
                reason  => "$!",
                file    => $name,
            };
        }
        else {
            $log->debug("moved");
            $status = {
                status  => 'ok',
                file    => $fqn,
            };
        }

        my $content_type    = $self->get_filetype($fqn);
        my $filedata        = read_file($fqn);
        my $filehref        = $self->hash_file($filedata);

        $filehref->{filename}   = $name;
        $filehref->{size}       = $size;
        $filehref->{directory}  = $dir;
        $filehref->{groups}     = $group_href;

        # Bug here to fix.  We do not  know the entry_id at this point
        # need to updated this after creating entry

        $filehref->{target}     = {
            type    => 'entry',
            id      => $entry_id,
        };
        $filehref->{entry_target}   = {
            type    => $target_type,
            id      => $target_id,
        };

        $log->debug("Creating File record with ",{filter=>\&Dumper, value=> $filehref});
        my $fileobj = $mongo->collection('File')->create($filehref);

        unless ( $fileobj ) {
            $log->error("Failed creation of file object ",
                        { filter => \&Dumper, value => $filehref });
            next UPLOAD;
        }

        $status->{id} = $fileobj->id;

        my $newentry = $self->create_file_upload_entry(
            $fileobj, $entry_id, $target_type, $target_id
        );

        $log->debug("newentry is ",{filter=>\&Dumper, value=> $newentry});

        my $newid;
        unless ($newentry) {
            $log->error("Failed to create file upload entry!");
            $newid  = $entry_id;
        }
        else {
            $newid = $newentry->id;
        }

        push @statuses, $status;
    }
    # TODO: think about harmonizing this with the returns that are expected
    # in API.pm
    $self->render(
        status  => 200, 
        json    => \@statuses);
    $self->put_stat("file uploaded", 1);
}

sub create_file_upload_entry {
    my $self        = shift;
    my $fileobj     = shift;
    my $parent_id    = shift;
    my $target_type = shift;
    my $target_id   = shift;
    my $fid         = $fileobj->id;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;
    my $col         = $mongo->collection('Entry');
    $log->debug("going to entry collection to create entry");
    my $entry       = $col->create_from_file_upload($fileobj,
                                                    $parent_id,
                                                    $target_type,
                                                    $target_id);
    $env->mq->send("scot", {
        action  => "created",
        data    => {
            type    => "entry",
            id      => $entry->id,
            who     => $self->session('user'),
            what    => "file_uploaded",
        }
    });
    $env->mq->send("scot", {
        action  => "updated",
        data    => {
            type    => $target_type,
            id      => $target_id,
            who     => $self->session('user'),
            what    => "file_uploaded",
        }
    });
    return $entry;
}

sub get_groups_and_year {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $col = $mongo->collection(ucfirst($type));
    my $obj = $col->find_iid($id);

    my $nowdt   = DateTime->now();

    unless ( $obj ) {
        $log->error("Failed to get target object!");
        return $env->default_groups, $nowdt->year;
    }

    my $dt;
    if ( $type eq "entity" ) {
        $dt = $nowdt; # entities don't have the Times Role, so just put now in there
    }
    else {
        $dt = DateTime->from_epoch(epoch => $obj->when);
    }

    return $obj->groups, $dt->year;
}




sub hash_file {
    my $self    = shift;
    my $data    = shift;
    my %hashes  = (
        md5     => md5_hex($data),
        sha1    => sha1_hex($data),
        sha256  => sha256_hex($data),
    );
    return wantarray ? %hashes : \%hashes;
}

sub get_targets {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    my $entry_id   = $self->param('entry_id');
    my $target_id;
    my $target_type;

    unless ( $entry_id ) {
        $entry_id   = 0; # this will be the parent of the file upload entry
        $target_type    = $self->param('target_type');
        $target_id      = $self->param('target_id') + 0;
        my $msg;

        unless ( $target_type ) {
            $msg = "You must provide target_type and target_id, or entry_id";
            $log->error($msg);
            $self->render({
                status  => 400,
                json    => { error_msg => $msg },
            });
            return undef, undef, undef;
        }

        my $collection = $mongo->collection(ucfirst($target_type));

        unless ($collection) {
            $msg    = "invalid collection $target_type as target";
            $log->error($msg);
            $self->render({
                status  => 400,
                json    => { error_msg => $msg }
            });
            return undef, undef, undef;
        }
    }
    else {
        my $msg;
        $target_type    = $self->param('target_type');
        $target_id      = $self->param('target_id') + 0;
        unless ( $target_type ) {
            $msg = "You must provide target_type and target_id, or entry_id";
            $log->error($msg);
            $self->render({
                status  => 400,
                json    => { error_msg => $msg },
            });
            return undef, undef, undef;
        }

        my $collection = $mongo->collection(ucfirst($target_type));

        unless ($collection) {
            $msg    = "invalid collection $target_type as target";
            $log->error($msg);
            $self->render({
                status  => 400,
                json    => { error_msg => $msg }
            });
            return undef, undef, undef;
        }
    }
    return $entry_id, $target_type, $target_id;
}

sub get_filetype {
    my $self    = shift;
    my $name    = shift;
    my $path    = sprintf("<%s", $name);
    my $file_type   = File::Type->new();
    my $content_type    = $file_type->mime_type($path);
    return $content_type;
}


1;
