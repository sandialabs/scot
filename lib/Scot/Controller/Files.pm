package Scot::Controller::Files;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Util::Mongo;
use JSON;
use Time::HiRes qw(gettimeofday);
use MIME::Base64;
use File::Temp;
use Mojo::Asset::File;
use File::Path qw(make_path);
use File::Copy;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex sha256_hex);;
use File::Slurp;

use Scot::Model::Entry;
use Scot::Model::File;
use Mojolicious::Static;
# use Mojolicious::Plugin::RenderFile;

use base 'Mojolicious::Controller';

sub process_post_data {
    my $self    = shift;
    my $data    = shift;
    my $asset   = Mojo::Asset::File->new;
    my $decode  = decode_base64($data);
    my $upload  = Mojo::Upload->new;

    $asset->add_chunk($decode);
    $upload->filename($self->param('filename'));
    $upload->asset($asset);
    return $upload;
}

=head2 update

  file uploaded to update SCOT

=cut

sub update {
    my $self        = shift;
    my $log         = $self->app->log;
    my $status      = {};

    $log->debug("Receiving File(s)");

    my @uploads     = $self->req->upload('upload');
    my $who         = $self->session('user');
    
    my @statuses    = ();

    foreach my $upload (@uploads) {
        my $size    = $upload->size;
        my $name    = $upload->filename;


        my $dir     = join( '/', 
                        $self->fs_root,
                        'update');

        unless ( -d $dir ) {
            my $err;
            make_path($dir, 
                { error=> \$err, mode => 0775, owner => "scot", group => "scot"}
            );
            if ( @$err ) {
                for my $diag (@$err) {
                    my ( $file, $msg ) = %$diag;
                    if ( $file eq '') {
                        $log->error("General Mkpath Error: $msg");
                    }
                    else {
                        $log->error("Mkpath $file : $msg");
                    }
                }
            }
        }

        my $newfilename = $dir . '/' . $name;
        if ( -e $newfilename) {
            $newfilename    .= "." . time();
        }

        $upload = $upload->move_to($newfilename);

        if ( $! ) {
            $status = {
                status  => 'failed',
                reason  => "$!",
                file    => "name",
            };
        }
        else {
            $status = {
                status  => 'ok',
                file    => $newfilename,
            };
        }

        my $content_type    = $self->get_filetype($newfilename);
        my $filedata        = read_file($newfilename);
        push @statuses, $status;
    }
    $self->render(json => \@statuses);
}
=head2 recieve

 store uploaded file and create metadata record

=cut

sub receive {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $status      = {};

    $log->debug("Receiving File(s)");

    my @uploads     = $self->req->upload('upload');
    my $who         = $self->session('user');
    my $target      = $self->param('target_type');
    my $target_id   = $self->param('target_id')+ 0;
    my $entry_id    = $self->param('entry_id') + 0;
    my $notes       = $self->param('notes');
    my @rg          = split(',',$self->param('readgroups'));
    my @mg          = split(',',$self->param('modifygroups'));
    
    my @statuses    = ();

    foreach my $upload (@uploads) {
        my $size    = $upload->size;
        my $name    = $upload->filename;

        my $fy      = $self->get_fy();

        my $dir     = join( '/', 
                        $self->fs_root,
                        $fy,
                        $target,
                        $target_id);

        $log->debug("Checking for $dir existance");

        unless ( -d $dir ) {
            $log->debug("need to create $dir");
            my $err;
            make_path(
                $dir, 0775, {
                    error   => \$err,
                    owner   => "scot",
                    group   => "scot",
                    mode => 0775, 
                },
            );
            if ( @$err ) {
                for my $diag (@$err) {
                    my ( $file, $msg ) = %$diag;
                    if ( $file eq '') {
                        $log->error("General Mkpath Error: $msg");
                    }
                    else {
                        $log->error("Mkpath $file : $msg");
                    }
                }
            }
        }

        my $newfilename = $dir . '/' . $name;
        if ( -e $newfilename) {
            $newfilename    .= "." . time();
        }

        $upload = $upload->move_to($newfilename);

        if ( $! ) {
            $status = {
                status  => 'failed',
                reason  => "$!",
                file    => "$name",
            };
        }
        else {
            $status = {
                status  => 'ok',
                file    => $newfilename,
            };
        }

        my $content_type    = $self->get_filetype($newfilename);
        my $filedata        = read_file($newfilename);

        $log->debug("   N A M E is ".$name);

        my $metahref        = {
            owner           => $who,
            target_type     => $target,
            target_id       => $target_id,
            entry_id        => $entry_id,
            size            => $size,
            dir             => $dir,
            filename        => $name,
            where           => $newfilename,
            content_type    => $content_type,
            notes           => $notes,
            fullname        => $newfilename,
            readgroups      => \@rg,
            modifygroups    => \@mg,
            sha1            => sha1_hex($filedata),
            sha256          => sha256_hex($filedata),
            md5             => md5_hex($filedata),
            env             => $env,
        };
        $self->create_or_update_file_obj($metahref);

        push @statuses, $status;
    }
    $self->render(json => \@statuses);
}

sub get_filetype {
    my $self            = shift;
    my $name            = shift;
    my $path            = sprintf("<%s", $name);
    my $file_type       = File::Type->new();
    my $content_type    = $file_type->mime_type($path);
    return $content_type;
}

sub get_sha1 {
    my $self    = shift;
    my $fh      = shift;
    my $sha1    = Digest::SHA1->new;
    $sha1->addfile($fh);
    my $digest = $sha1->hexdigest();
    undef $sha1;
    return $digest;
}

sub get_sha256 {
    my $self    = shift;
    my $fh      = shift;
    my $sha     = Digest::SHA->new(256);
    $sha->addfile($fh);
    my $digest  = $sha->hexdigest();
    undef $sha;
    return $digest;
}

sub get_md5 {
    my $self    = shift;
    my $fh      = shift;
    my $md5     = Digest::MD5->new;
    $md5->addfile($fh);
    my $digest  = $md5->hexdigest();
    undef $md5;
    return $digest;
}

sub create_or_update_file_obj {
    my $self    = shift;
    my $href    = shift;
    my $mongo   = $self->env->mongo;
    my $log     = $self->app->log;
    my $env     = $self->env;
    $href->{log} = $log;

    $log->debug(" N A M E is now ".$href->{filename});

    my $obj = Scot::Model::File->new($href);
    $obj->controller($self);
    my $id  = $mongo->create_document($obj);
    delete $href->{log};

    my $activity_href   = {
        who     => $self->session('user'),
        when    => time(),
        type    => "upload",
        what    => "file_upload",
        data    => $href,
        xid     => 0,
    };

    $href->{file_id} = $id;
    if (defined $href->{entry_id} && $href->{entry_id} > 0) {
        $log->debug("we have an entry_id!");
        my $entry   = $mongo->read_one_document({
            collection  => "entries",
            match_ref   => { entry_id   => $href->{entry_id} },
        });
        if (defined $entry ) {
            $entry->controller($self);
            $entry->env($env);
            $log->debug("Appending to Entry");
            my $text    = $entry->body;
            $text       .= $self->file_blurb($href);
            $entry->body($text);
            $mongo->update_document($entry);

            $entry->add_self_to_entities([
                { type => "file", value => $href->{filename} }
            ]);

            $env->update_activity_log({
                who     => $self->session('user'),
                what    => "updated entry ". $href->{entry_id},
                when    => $env->now(),
            });
            $env->activemq->send("activity", {
                action  => "update",
                type    => "entry",
                id      => $href->{entry_id},
                is_task => $href->{is_task},
                target_type     => $href->{target_type},
                target_id       => $href->{target_id},
            });
        }
        else {
            $log->debug("Creating new entry");
            $log->debug(" N A M E should still be ". $href->{filename});
            $href->{entry_id} = $self->create_this_entry($href);
            $env->update_activity_log({
                who     => $self->session('user'),
                what    => "created entry ". $href->{entry_id},
                when    => $env->now(),
            });
            my $mhref   = {
                action          => "creation",
                type            => "entry",
                id              => $href->{entry_id}+0,
                target_type     => $href->{target_type},
                target_id       => $href->{target_id}+0,
            };
            $log->error("SENDING THE FOLLOWING TO ACTIVEMQ:",
                        { filter=>\&Dumper, value => $mhref});
            $env->activemq->send("activity", $mhref);
        }
    }
    else {
        $log->debug("Creating new entry");
        $log->debug("IS N A M E still ".$href->{filename});
        $href->{entry_id} = $self->create_this_entry($href);
        $env->update_activity_log({
            who     => $self->session('user'),
            what    => "created entry ". $href->{entry_id},
            when    => $env->now(),
        });
        my $mhref   = {
            action          => "creation",
            type            => "entry",
            id              => $href->{entry_id}+0,
            target_type     => $href->{target_type},
            target_id       => $href->{target_id}+0,
        };
        $log->error("SENDING THE FOLLOWING TO ACTIVEMQ:",
                    { filter=>\&Dumper, value => $mhref});
        $env->activemq->send("activity", $mhref);
    }
}

sub create_this_entry {
    my $self     = shift;
    my $href     = shift;
    my $env      = $self->env;
    my $log      = $env->log;
    my $mongo    = $env->mongo;
    $log->debug("in create_this_entry");
    my $entry_obj   = Scot::Model::Entry->new({
        body        => $self->file_blurb($href),
        target_id   => $href->{target_id},
        target_type => $href->{target_type},
        log         => $log,
        owner       => $href->{owner},
        env         => $env,
    });
    $entry_obj->controller($self);
    my $entry_id = $mongo->create_document($entry_obj);
    $entry_obj->entry_id($entry_id);
    $entry_obj->add_self_to_entities([
        { type => "file", value => $href->{filename} }
    ]);
    return $entry_id + 0;
}

=item
            owner           => $who,
            target_type     => $target,
            target_id       => $target_id,
            entry_id        => $entry_id,
            size            => $size,
            dir             => $dir,
            filename        => $name,
            where           => $newfilename,
            content_type    => $content_type,
            notes           => $notes,
            fullname        => $newfilename,
            readgroups      => \@rg,
            modifygroups    => \@mg,
=cut 

sub file_blurb {
    my $self    = shift;
    my $href    = shift;
    my $text    = qq|
<div class="fileinfo">
    <table class="filetable">
        <tr><th>file_id     </th><td>%s</td></tr>
        <tr><th>filename    </th><td>%s/%s</td></tr>
        <tr><th>size        </th><td>%d</td></tr>
        <tr><th>notes       </th><td>%s</td></tr>
        <tr><th>md5         </th><td>%s</td></tr>
        <tr><th>sha1        </th><td>%s</td></tr>
        <tr><th>sha256      </th><td>%s</td></tr>
        <tr><th colspan=2>
                <a href="/scot/file/%d?download=1">Download</a> &nbsp;
                <span data-entity-value="%d" data-entity-type="file" class="entity file">
                   Action
                </span>
                %s
            </th>
        </tr>
    </table>
</div>
|;
    return sprintf( $text,
                    $href->{file_id},
                    $href->{dir} // '-',
                    $href->{fullname} // '-',
                    $href->{size} // '-',
                    $href->{notes} // '-',
                    $href->{md5} // '-',
                    $href->{sha1} // '-',
                    $href->{sha256} // '-',
                    $href->{file_id} // '-',
                    $href->{file_id} // '-',
                    $href->{filename} // '-');
}

sub digests_differ {
    my $self    = shift;
    my $meta    = shift;
    my $fullname    = $meta->{fullname};

    my $fh  = FileHandle->new();
    $fh->open("< $fullname");
    my $md5 = Digest::MD5->new;
       $md5->addfile($fh);

    if ($md5->digest ne $meta->{md5}) {
        return 1;
    }
    return undef;
}



=head2 get

 retrieve metadata about a file

=cut

sub get {
    my $self    = shift;
    my $log     = $self->app->log;
    my $mongo   = $self->env->mongo;
    my $id      = $self->stash("id") + 0;
    my $dload   = $self->param('download');

    my $gridconf    = $self->parse_grid_settings($self->req);
    my $colconf     = {};
    my $opts_ref    = {
        collection  => "files"
    };
    
    $log->debug("Getting file: $id");

    if ( defined $id ) {
        $opts_ref->{match_ref}   = { file_id => $id };
    }
    else {
        $opts_ref->{match_ref}  = {};
        $opts_ref->{start}      = $gridconf->{start};
        $opts_ref->{limit}      = $gridconf->{limit};
        $opts_ref->{sort_ref}   = $gridconf->{sort_ref};
        $colconf                = $self->parse_cols_requested($self->req);
    }

    my $cursor  = $mongo->read_documents($opts_ref);
    my @data    = ();

    while ( my $obj = $cursor->next ) {
        $obj->log($log);
        $log->debug("Retrieved File id: " . $obj->file_id);
        if (  $obj->is_readable($self->session('groups')) ) {
            my $href;
            if (defined $gridconf) {
                $href    = $obj->grid_view_hash($colconf);
            }
            else {
                $href   = $obj->as_hash;
            }
            if (defined $href) {
                push @data, $href;
            }
        }
    }

    $log->debug("data is ".Dumper(\@data));

    if ( scalar(@data) > 0 ) {
        if ($dload) {
            my $fullname    = $data[0]->{fullname}; #absolute path to file i.e. /opt/scotfiles/event/5...
            my $filename    = $data[0]->{filename}; #filename of file i.e. 'loading.gif'
            my $file        = read_file($fullname);
            $self->res->content->headers->header(
                'Content-Type', "application/x-download; name=\"$filename\"");
            $self->res->content->headers->header(
                'Content-Disposition', "attachment;filename=\"$filename\"");
            $self->render(data=>$file);
        }
        else {
            $self->render(
                json    => {
                    title   => 'File List',
                    action  => "get",
                    thing   => "file",
                    status  => 'ok',
                    data    => \@data,
                }
            );
        }
    }
    else {
        $self->render(
            json    => {
                title   => "File List",
                action  => 'get',
                thing   => "file",
                status  => "no matching permitted records",
            }
        );
    }
}



sub download {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $id      = $self->stash("id") + 0;

    my $object  = $mongo->read_one_document({
        collection  => "files",
        match_ref   => { file_id => $id },
    });
    my $activity_href;
    my $status_ref;

    if ($object) {

        if ( $object->is_readable($self->session('groups')) ){
            $activity_href   = {
                who     => $self->session('user'),
                what    => "file download",
                when    => time(),
                type    => "download",
                data    => {
                    target_type     => "file",
                    target_id       => $id,
                    original_obj    => {
                        target_id       => $object->target_id,
                        tareget_type    => $object->target_type,
                    }
                },
            };

            my $shortname   = $object->filename;
            my $fullname    = $object->fullname;
            my $filedata    = read_file($fullname);

            if ($filedata) {
                $self->res->content->headers->header(
                    'Content-Type', "application/x-download; name=\"$shortname\"");
                $self->res->content->headers->header(
                    'Content-Disposition', "attachment; filename=\"$shortname\"");

                my $static = Mojolicious::Static->new( paths => [ $object->dir ] );
                $static->serve($self, $shortname);
                $self->rendered;
                $status_ref = {
                    title   => "Download",
                    action  => "get",
                    thing   => "file",
                    id      => $id,
                    status  => "ok",
                };
            }
            else {
                $log->error("Failed to slurp $fullname");
                $status_ref = {
                    title   => "Download",
                    action  => "get",
                    thing   => "file",
                    id      => $id,
                    status  => "failed",
                };
            }
        }
        else {
            $log->error("Read not permitted file $id");
            $activity_href    = {
                who     => $self->session('user'),
                what    => "file download",
                when    => time(),
                type    => "download",
                data    => { status => "failed" },
            };
            $status_ref = {
                title   => "Download",
                action  => "get",
                thing   => "file",
                id      => $id,
                status  => "failed",
            };
        }

    }
    else {
        $log->error("Failed to match file $id");
        $activity_href    = {
            who     => $self->session('user'),
            what    => "file download",
            when    => time(),
            type    => "download",
            data    => { status => "failed" },
        };
        $status_ref = {
            title   => "Download",
            action  => "get",
            thing   => "file",
            id      => $id,
            status  => "failed",
        };
    }
    $env->update_activity_log($activity_href);
#    $self->render(json => $status_ref);
}

sub get_fy {
    my $self    = shift;
    my $dt      = shift;
    unless (defined $dt) {
        $dt = DateTime->now();
    }
    my $year    = $dt->year;
    my $month   = $dt->month;

    if ($month > 9) {
        $year++;
    }
    return substr($year, -2);
}
1;
