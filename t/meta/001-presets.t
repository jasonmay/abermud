#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar ();

my $game = AberMUD::Test::Sugar::build_preset_game('square');

ok($game);

my $config = $game->resolve(service => 'storage')->lookup('config');

ok($config);
ok($config->location);

my $l = $config->location;

is($l->title,              'Northwest Corner');
is($l->east->title,        'Northeast Corner');
is($l->south->title,       'Southwest Corner');
is($l->south->east->title, 'Southeast Corner');

is($l->south->east, $l->east->south);
is($l->east,        $l->south->east->north);

done_testing();
