#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar qw(build_preset_game);
use AberMUD::Util;
use AberMUD::Object;

my ($gizmo, $doodad) = (
    AberMUD::Object->with_traits('Getable')->new(
        name      => 'gizmo',
        buy_value => 42,
    ),
    AberMUD::Object->with_traits('Getable')->new(
        name      => 'doodad',
        buy_value => 100,
    ),
);
my ($c, $locations) = build_preset_game(
    'two_wide',
    {
        locations => {
            room1 => {
                traits => ['Shop'],
                extra_params => {
                    _stock_objects => {
                        gizmo => {
                            object => $gizmo,
                        },
                        doodad => {
                            object => $doodad,
                        },
                    },
                },
            },
        },
    }
);

my $b = $c->controller->backend;

ok($locations->{room1}->does('AberMUD::Location::Role::Shop'));

my $conn = $b->new_player('jason');

$conn->associated_player->money(90);
like($b->inject_input($conn, 'buy gizmo'),  qr/You buy the gizmo for 42 coins./);
like($b->inject_input($conn, 'buy doodad'), qr/You can't afford that./);

like($b->inject_input($conn, 'inventory'),  qr/gizmo/);

done_testing();
