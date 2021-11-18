package Scot::Flair3::Web;

use Moose;

use feature qw(signatures);
no warnings qw(experimental::signatures);
use utf8;
use lib '../../../lib';

use Mojo::UserAgent;
use Data::Dumper;
use Log::Log4perl;
use Digest::MD5 qw(md5_hex);

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    default     => sub { Log::Log4perl->get_logger('Flair'); },
);

has http_proxy  => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_http_proxy',
);

has https_proxy => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_https_proxy',
);

has no_proxy    => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_no_proxy',
);

sub set_proxy ($self, $ua) {
    my $log                 = $self->log;
    my $manual_set_proxy    = 0;

    if ($self->has_http_proxy) {
        $ua->proxy->http($self->http_proxy);
        $manual_set_proxy++;
    }
    if ($self->has_https_proxy) {
        $ua->proxy->https($self->https_proxy);
        $manual_set_proxy++;
    }
    if ($self->has_no_proxy) {
        $ua->proxy->not($self->no_proxy);
        $manual_set_proxy++;
    }

    if ( $manual_set_proxy < 1 ) {
        $ua->proxy->detect;
    }
    my $p = $ua->proxy;
    $log->debug("UA Proxy Settings");
    $log->debug("  http_proxy  = ".$p->http);
    $log->debug("  https_proxy = ".$p->https);
    $log->debug("  no_proxy    = ".$p->not);
}

has ua      => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_build_ua',
);

sub _build_ua ($self) {
    my $ua  = Mojo::UserAgent->new();
    $self->set_proxy($ua);
    return $ua;
}

sub get_image ($self, $uri, $destdir) {
    $self->log->debug("Requesting $uri");
    my $asset   = $self->ua->get($uri)->res->content->asset;
    my $newname = $self->build_new_name($uri, $asset);
    my $dest    = join('/',$destdir,$newname);
    $asset->move_to($dest);
    $self->log->debug("stored at $dest");
    return $dest;
}

sub build_new_name ($self, $uri, $asset) {
    my $hash    = md5_hex($asset->slurp);
    my $imgname = (split('/', $uri))[-1];       # get last part of uri
    $self->log->debug("imgname = $imgname");
    my $name    = (split('\?', $imgname))[0];   # throw away any params ?foo=bar
    $self->log->debug("name = $name");
    my $ext     = (split('.', $name))[-1];      # get jpg from foo.jpg if it exists
    $self->log->debug("ext = $ext");
    my $new     = join('.', $hash, $ext);
    return $new;
}

    
    

__PACKAGE__->meta->make_immutable;
1;

