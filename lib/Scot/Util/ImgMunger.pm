package Scot::Util::ImgMunger;

use v5.10;
use strict;
use warnings;
# use re 'debug';

use Readonly;
use HTML::TreeBuilder 5 -weak;
use HTML::FormatText;
use HTML::Element;
use Data::Dumper;
use MIME::Base64;
use LWP::UserAgent;
use LWP::Protocol::https;
use File::Slurp;
use Digest::MD5 qw(md5_hex);
use namespace::autoclean;

use Moose;
extends 'Scot::Util';

has html_root   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_html_root',
);

sub _build_html_root {
    my $self    = shift;
    my $attr    = "html_root";
    my $default = "/cached_images";
    my $envname = "scot_util_imgmunger_html_root";
    return $self->get_config_value($attr, $default, $envname);
}

has img_dir   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_img_dir',
);

sub _build_img_dir {
    my $self    = shift;
    my $attr    = "img_dir";
    my $default = "/opt/scot/public/cached_images";
    my $envname = "scot_util_imgmunger_img_dir";
    return $self->get_config_value($attr, $default, $envname);
}

has storage   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_storage',
);

sub _build_storage {
    my $self    = shift;
    my $attr    = "storage";
    my $default = "local";
    my $envname = "scot_util_imgmunger_storage";
    return $self->get_config_value($attr, $default, $envname);
}

sub process_html { 
    my $self    = shift;
    my $entry   = shift;    # this is html string
    my $id      = shift;
    my $log     = $self->log;


    return unless $entry;    # nothing to do

    my $tree    = HTML::TreeBuilder->new;
       $tree    ->implicit_tags(1);
       $tree    ->implicit_body_p_tag(1);
       $tree    ->p_strict(1);
       $tree    ->no_space_compacting(1);
       $tree    ->parse_content($entry);
       $tree    ->elementify;

    my @images  = @{ $tree->extract_links('img') };
    my @files   = ();

    foreach my $aref (@images) {
        $log->debug("Found Img Tag: ",{filter=>\&Dumper, value=> $aref});
        my ( $link,
            $element,
            $attr,
            $tag   ) = @{ $aref };

        my ($fqn, $fname);

        if ($link =~ m/^data:/) {
            $log->debug("Link contains data uri");
            ($fqn,$fname)   =  $self->extract_data_image($link, $id);
        }
        else {
            ($fqn,$fname) = $self->download_image($link);
        }
        $log->debug("NOW UPDATING the HTML");
        $self->update_html($element, $fqn, $fname);
    }

    my $new_html;

    my $body = $tree->look_down('_tag', 'body');
    my $div  = HTML::Element->new('div');
    $div->push_content($body->detach_content);

    return $div->as_HTML;
}

sub extract_data_image {
    my $self    = shift;
    my $link    = shift;
    my $id      = shift;
    my $log     = $self->log;

    $link =~ m/^data:(.*);(.*),(.*)$/;
    my $mimetype = $1;
    my $encoding = $2;
    my $data     = $3;

    $self->log->debug("mimetype = $mimetype encoding = $encoding");

    my ( $type, $ext ) = split('/', $mimetype);

    $log->debug("data is : $data");

    my $decoded         = decode_base64($data);
    my ($fqn, $fname)   = $self->create_file($decoded, $id, $ext);

    return $fqn, $fname;
}

sub download_image {
    my $self    = shift;
    my $link    = shift;
    my $log     = $self->log;
    my $agent   = LWP::UserAgent->new(
        env_proxy   => 1,
        timeout     => 10,
    );
    $agent->ssl_opts( SSL_verify_mode => 1, verify_hostname => 1, SSL_ca_path => '/etc/ssl/certs' );
    $agent->proxy(['http','https'], 'http://wwwproxy.sandia.gov:80');

    my $request     = HTTP::Request->new('GET', $link);
    my $response    = $agent->request($request);

    if ( $response->is_success() ) {
        my $filename        = ( split(/\//, $link) )[-1];
        my ($fqn, $fname)   = $self->create_file($response->content, $filename);
        return $fqn, $fname;
    }
    else {
        $log->error("Failed download of image $link");
        $log->error("Error Msg: ".$response->status_line);
        print "Failed to retrieve!\n";
        $log->error("Failed to retrieve $link, ".$response->status_line);
        die $response->status_line;
    }

}


# this create file assumes that we are on the scot server 
# need to create a version that will upload to the api

sub create_file {
    my $self        = shift;
    my $data        = shift;
    my $name        = shift;
    my $ext         = shift; 
    my $log         = $self->log;
    my $dir         = $self->img_dir;
    my $storage     = $self->storage;

    $log->debug("Creating File: $name");
    $log->debug("Storage method is ".$storage);

    if ( $storage eq 'local' ) {
        if ($name =~ /^\d+$/ ) {
            # create a name with low chance of collision
            $name   = md5_hex($data);
        }
        $name = $name . ".". $ext if ( $ext );
        $log->debug("dir = $dir name = $name");
        my $fqn = join('/',$dir,$name);
        $log->debug("file at $fqn");
        open my $fh, ">", "$fqn" or die $!;
        binmode $fh;
        print   $fh $data;
        close   $fh;
        return $fqn, $name;
    }
    # do api upload
    # mojo ua -> upload img
    # get the Scot::Model::CachedImage return code
    # return the $fqn, $name
}

sub update_html {
    my $self    = shift;
    my $element = shift;
    my $fqn     = shift;
    my $fname   = shift;
    my $log     = $self->log;

    $log->debug("html root is ".$self->html_root);
    $log->debug("fname is ".$fname);

    my $source  = $self->html_root . "/". $fname;
    my $alt     = $element->attr('alt');
    if ( $alt ) {
        $alt    = "ScotCopy of $alt";
    }
    else {
        $alt    = "Scot Cached Image";
    }
    my $newimg  = HTML::Element->new('img', 'src'   => $source, 'alt' => $alt);
    $element->replace_with($newimg);
}


1;
