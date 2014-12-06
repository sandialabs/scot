package Scot::Roles::Plaintextable;

use Data::Dumper;
use File::Temp;
use Moose::Role;
use namespace::autoclean;

sub get_plaintext {
    my $self    = shift;
    my $type    = ref($self);

    if ($type eq "Scot::Model::Alert") {
        return $self->get_plaintext_lynx();
    }
    return $self->body_plaintext();
}


sub get_plaintext_lynx {
    my $self    = shift;
    my $html    = $self->build_text_from_data;
    my $tmp     = File::Temp->new(
        TEMPFILE    => 'ptrenderXXXXXXX',
        DIR         => '/tmp',
        SUFFIX      => '.html',
        UNLINK      => 1,
    );
    binmode($tmp, ":utf8");
    print $tmp $html;
    my $file    = $tmp->filename;
    my $plain   = `lynx --dump --nonumbers --width 9999 $file`;
    return $plain;
}

sub build_text_from_data {
    my $self    = shift;
    my $data    = $self->data;
    my $html    = "<html>";

    while ( my ($k, $v) = each %$data ) {
        $html .= "<p>$k = $v</p>";
    }
    $html   .= "</html>";
    return $html;
}

sub build_text_table {
    my $self    = shift;
    my $data    = $self->data;
    my $html    = "<table>";
    my $log     = $self->log;

    $log->debug("building table...");
    while ( my ($k, $v) = each %$data ) {
        $log->debug("$k => $v");
        $html .= "<tr><th>$k</th><td>$v</td></tr>";
    }
    $html .= "</table>";
    return $html;
}

sub build_search_text {
    my $self    = shift;
    my $data    = $self->data;
    my $text    = "";

    while ( my ($k, $v) = each %$data ) {
        unless( defined $v ) { $v = ''; }
        if ( ref($v) eq "ARRAY" or ref($v) eq "HASH" ) {
            local $Data::Dumper::Indent = 0;
            $v = Dumper($v);
        }
        $text   .= qq| $k => $v ~~ |;
    }
    return $text;
}


1;
