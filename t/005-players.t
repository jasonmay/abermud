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
my $u = $c->universe;
my $b = $c->controller->backend;

my ($one, $conn_one) = $b->new_player('playerone');
my ($two, $conn_two) = $b->new_player('playertwo');

like($b->inject_input($conn_one, 'look'),  qr{playertwo is standing here}i);
like($b->inject_input($conn_one, 'east'),  qr{second});
like($conn_two->get_output,        qr{playerone goes east}i);
like($b->inject_input($conn_two, 'east'), qr{playerone is standing here}i);
like($conn_one->get_output,        qr{playertwo arrives from the west}i);

$b->inject_input($conn_one, 'west');
$b->inject_input($conn_one, 'east');

like($conn_two->get_output, qr{playerone goes west});
like($conn_two->get_output, qr{playerone arrives from the west});

$one->score(2000);
is($one->level, 1);

$one->score(7999);
is($one->level, 2);

$one->score(8000);
is($one->level, 3);

$one->score(8001);
is($one->level, 3);

$one->score(7999);

$one->clear_output_buffer;
$u->change_score($one, 1);
$conn_one->flush_output;
like($conn_one->get_output, qr{congratulations! you made it to level .*3}i);

$one->take_damage($u, $one->max_strength);
ok($one->dead);

done_testing();
