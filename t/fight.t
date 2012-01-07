#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar qw(build_preset_game);
use AberMUD::Util;

my $c = build_preset_game(
    'two_wide',
    extra => [
        {
            locations => {
                room1 => {
                    has_mobiles => {
                        knight => {
                            description  => 'A knight is standing here.',
                            pname        => 'Knight',
                            examine      => 'very metallic',
                            basestrength => 100,
                        },
                    },
                },
            },
        },
    ],
);

my $u = $c->universe;
my $b = $c->controller->backend;

ok(my @m = $u->get_mobiles, 'mobiles loaded');

my %mobiles                       = map { $_->name => $_ } @m;
my ($one, $conn_one)              = $b->new_player('playerone');
my ($two, $conn_two)              = $b->new_player('playertwo');

ok($mobiles{knight});
ok($mobiles{knight}->description);

is($one->location, $mobiles{knight}->location);

like($b->inject_input($conn_one, 'kill knight'), qr{You engage in battle with Knight!});
ok($one->fighting);
ok($mobiles{knight}->fighting);
is($one->fighting, $mobiles{knight});
is($mobiles{knight}->fighting, $one);

$u->attack(
    attacker => $one,
    victim   => $mobiles{knight},
    damage   => 99,
    bodypart => 'head',
    message  => "%a deliver%s a mighty blow to %p %b!",
);

$conn_one->flush_output;
like($conn_one->get_output, qr/You deliver a mighty blow to Knight's &\+Rhead&N!/);

$conn_two->flush_output;
like($conn_two->get_output, qr/Playerone delivers a mighty blow to Knight's &\+Rhead&N!/);

ok(!$mobiles{knight}->dead, 'the knight is still alive');

$u->attack(
    attacker => $mobiles{knight},
    victim   => $one,
    damage   => $one->current_strength - 1,
    bodypart => 'back',
    message  => "%a deliver%s a mighty blow to %p %b!",
);

$conn_one->flush_output;
like($conn_one->get_output, qr/Knight delivers a mighty blow to your &\+gback&N!/);

$conn_two->flush_output;
like($conn_two->get_output, qr/Knight delivers a mighty blow to playerone's &\+gback&N!/);

done_testing();
