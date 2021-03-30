#!/usr/bin/env perl

use lib '../../../../lib';
use Scot::Email::Parser::PassThrough;
use Scot::Env;
use Test::More;
use Test::Deep;
use Data::Dumper;

my $env = Scot::Env->new(
    config_file => '../../../../../Scot-Internal-Modules/etc/mailtest.cfg.pl'
);

my $parser  = Scot::Email::Parser::PassThrough->new(
    env => $env
);

my $body_html = <<'EOF';
<html><head></head><body><h1>Foobar</h1><p>Tests again </body></html>
EOF

my $body_plain = << 'EOF';
   Foobar
   ======

   Tests again
EOF

my $message = {
    from        => 'mow@watermelon.com',
    subject     => 'FOOBAR',
    message_id  => '<b02629f38b2d4bcba45a10b50d7d43322@foobar.watermelon.com>',
    body_html   => $body_html,
    # TODO: images => [],
    # TODO: attachments => [],
};

my %result = $parser->parse_message($message);
chomp($body_html);

is($result{subject},    $message->{subject}, "Correct Subject");
is($result{message_id}, $message->{message_id}, "Correct Message id");
is($result{body_plain}, $body_plain, "Correct plain text");
is($result{body},       $body_html, "Correct html text");
is($result{columns}->[0], 'email', "tag is correct");
is($result{data}->[0]->{email}, $body_html, "entry data correct");
# TODO: check attachments


done_testing();
