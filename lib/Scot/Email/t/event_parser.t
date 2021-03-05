#!/usr/bin/env perl

use lib '../../../../lib';
use Scot::Email::Parser::Event;
use Scot::Env;
use Test::More;
use Test::Deep;
use Data::Dumper;

my $env = Scot::Env->new(
    config_file => '../../../../../Scot-Internal-Modules/etc/mailtest.cfg.pl'
);

my $parser  = Scot::Email::Parser::Event->new(
    env => $env
);

my $entry_body = << 'EOF';
<p>This is a test body of the Entry
EOF

chomp($entry_body);

my $body_html = <<"EOF";
<html>
    <body>
        <table>
            <tr><td>subject</td><td>It's foo time</td></tr>
            <tr><td>sources</td><td>me, myself, i</td></tr>
            <tr><td>tags</td><td>boom, baz, bar</td></tr>
        </table>
        $entry_body
    </body>
</html>
EOF

my $stripped_body = join('', 
 "<html><head></head><body><table></table>",
 $entry_body,
 " </body></html>"
);

my $body_plain = << 'EOF';
doesn't matter
EOF

my $message = {
    from    => 'todd@scot.com',
    subject => 'FOOBAR is at it again',
    message_id  => '<b02629f38b2d4bcba45a10b50d7db312@foobar.scot.com>',
    body_plain  => $body_plain,
    body_html   => $body_html,
};

my %result = $parser->parse_message($message);

is($result{event}{subject},    $message->{subject}, "Correct Subject");
is($result{entry}{body}, $stripped_body, "Entry Body correct");
cmp_deeply($result{event}{groups}, $env->default_groups, "Event groups correct");
cmp_deeply($result{entry}{groups}, $env->default_groups, "Entry groups correct");

cmp_deeply($result{event}{source}, [qw(me myself i)], "Source is correct");
cmp_deeply($result{event}{tag},    [qw(boom baz bar)], "Tag is correct");

done_testing();
