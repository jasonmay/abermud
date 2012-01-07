#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Zone;
use AberMUD::Input::State::Game;
use AberMUD::Config;
use AberMUD::Test::Sugar qw(build_preset_game);

my ($c, $locations) = build_preset_game('two_wide');
my $u = $c->universe;
my $b = $c->controller->backend;

my ($p, $conn) = $b->new_player('myplayer');

my $look = $b->inject_input($conn, 'look');
like($look,  qr{Room One}, 'player sees location title');
like($look,  qr{first room}, 'player sees location description');
like($look,  qr{East\s*:\s+Room Two}, 'player sees location description');

like($b->inject_input($conn, 'east'),  qr{second}, 'player successfully goes east');

done_testing();
