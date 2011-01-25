#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Test::Sugar qw(build_preset_game);
use AberMUD::Util;
use AberMUD::Object;

my ($c, $locations) = build_preset_game(
    'two_wide',
    {
        locations => {
            room1 => {
                traits => ['Shop'],
                extra_params => {
                    stock_objects => {
                        gizmo => AberMUD::Object->new(
                            buy_value => 42,
                            traits => ['Getable'],
                        ),
                        doodad => AberMUD::Object->new(
                            buy_value => 100,
                            traits => ['Getable'],
                        ),
                    },
                },
            },
        },
    }
);


ok($locations->{room1}->does('AberMUD::Location::Role::Shop'));

my $p = $c->gen_player('jason');

#$p->add_money(
$p->types_in('buy gizmo');

done_testing();
