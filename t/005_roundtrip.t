use strict;
use warnings;
use FindBin ();
BEGIN { require "$FindBin::Bin/etc/legacy.pl" }

use File::HomeDir::Test;
use Test::More tests => 55;
use Test::Mojo;
use Mojo::ByteStream qw/b/;
use File::Temp;
use Yars;

my $t = Test::Mojo->new('Yars');
my $root = File::Temp->newdir(CLEANUP => 1);
$t->app->config->servers(
    default => [{
        disks => [ { root => $root, buckets => [ '0' .. '9', 'A' .. 'F' ] } ]
    }]
);
$t->app->config->{url} = $t->ua->app_url;
$t->app->config->servers->[0]{url} = $t->app->config->{url};

{
    my $content = 'Yabba Dabba Dooo!';
    my $digest = b($content)->md5_sum->to_string;
    my $file = 'fred.txt';

    $t->put_ok("/file/$file", {}, $content)->status_is(201);
    my $location = $t->tx->res->headers->location;
    ok $location, "got location header";
    $t->get_ok("/file/$file/$digest")->status_is(200)->content_is($content);
    chomp (my $b64 = b(pack 'H*',$digest)->b64_encode);
    is $t->tx->res->headers->header("Content-MD5"), $b64;
    $t->get_ok("/file/$digest/$file")->status_is(200)->content_is($content);
    $t->get_ok($location)->status_is(200)->content_is($content);
    is $t->get_ok("/disk/usage?count=1")->status_is(200)->tx->res->json->{$root}{count}, 1;

    # Idempotent PUT
    $t->put_ok("/file/$file", {}, $content)->status_is(200);
    my $location2 = $t->tx->res->headers->location;
    is $location, $location2, "same location header";
    is $t->get_ok("/disk/usage?count=1")->status_is(200)->tx->res->json->{$root}{count}, 1;
    $t->head_ok($location)->status_is(200);
    is $t->tx->res->headers->content_length, b($content)->size, "Right content-length in HEAD";
    is $t->tx->res->headers->content_type, "text/plain", "Right content-type in HEAD";
    ok $t->tx->res->headers->last_modified, "last-modified is set";
    $t->delete_ok("/file/$file/$digest")->status_is(200);
}

{
    # Same filename, different content
    my $nyc = $t->put_ok("/file/houston", {}, "a street in nyc")->status_is(201)->tx->res->headers->location;
    my $tx = $t->put_ok("/file/houston", {}, "we have a problem")->status_is(201)->tx->res->headers->location;
    ok $nyc ne $tx, "Two locations";
    $t->get_ok($nyc)->content_is("a street in nyc");
    $t->get_ok($tx)->content_is("we have a problem");
    $t->delete_ok($nyc);
    $t->delete_ok($tx);
}

{
    # Same content, different filename
    my $content = "sugar filled soft drink that is bad for your teeth";
    my $md5 = b($content)->md5_sum;
    my $coke = $t->put_ok("/file/coke", {}, $content)->status_is(201)->tx->res->headers->location;
    my $pepsi = $t->put_ok("/file/pepsi", {}, $content)->status_is(201)->tx->res->headers->location;
    ok $coke ne $pepsi, "Two locations";
    $t->get_ok($coke)->content_is($content);
    $t->get_ok($pepsi)->content_is($content);
    my $coke_file = join '/', $root, ($md5 =~ /(..)/g), 'coke';
    ok -e $coke_file, "wrote $coke_file";
    my $pepsi_file = join '/', $root, ($md5 =~ /(..)/g), 'pepsi';
    ok -e $pepsi_file, "wrote $pepsi_file";
    my @coke = split / /, `ls -i $coke_file`;
    my @pepsi = split / /, `ls -i $pepsi_file`;
    like $coke[0], qr/\d+/, "found inode number $coke[0]";
    is $coke[0],$pepsi[0], 'inode numbers are the same';
    $t->delete_ok($coke);
    $t->delete_ok($pepsi);
}