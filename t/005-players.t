#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Container;
use AberMUD::Zone;
use AberMUD::Input::State::Game;
use AberMUD::Config;
use AberMUD::Test::Sugar qw(build_preset_game);

my ($c, $locations) = build_preset_game('two_wide');
my $u = $c->resolve(service => 'universe');

my $one = $c->gen_player('playerone');
my $two = $c->gen_player('playertwo');

like($one->types_in('look'),  qr{playertwo is standing here}i);
like($one->types_in('east'),  qr{second});
like($two->get_output,        qr{playerone goes east}i);
like($two->types_in('east'), qr{playerone is standing here}i);
like($one->get_output,        qr{playertwo arrives from the west}i);

$one->types_in('west');
$one->types_in('east');

like($two->get_output, qr{playerone goes west});
like($two->get_output, qr{playerone arrives from the west});

$one->score(2000);
is($one->level, 1);

$one->score(7999);
is($one->level, 2);

$one->score(8000);
is($one->level, 3);

$one->score(8001);
is($one->level, 3);

done_testing();
