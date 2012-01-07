#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Zone;
use AberMUD::Input::State::Game;
use AberMUD::Config;
use AberMUD::Test::Sugar qw(build_preset_game);
use AberMUD::Special;
use AberMUD::Special::Hook::Command;

my ($c, $locations) = build_preset_game(
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
                        monster => {
                            description  => 'A monster is standing here.',
                            pname        => 'Monster',
                            examine      => 'very monstrous',
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

my %mobiles = map { $_->name => $_ } $u->get_mobiles;

$c->special->hooks->{command} = [
    AberMUD::Special::Hook::Command->new(
        command_name => 'jump',
        before_block => sub { (1, "HOOK TRIGGER") },
    ),
];
$c->special->hooks->{death} = [
    AberMUD::Special::Hook::Death->new(
        victim => $mobiles{knight},
        before_block => sub { (1, "DEATH TRIGGER") },
    ),
    AberMUD::Special::Hook::Death->new(
        victim => $mobiles{monster},
        after_block => sub { (0, "MONSTER TRIGGER") },
    ),
];

my ($one, $conn_one) = $b->new_player('playerone', special => $c->special);

like($b->inject_input($conn_one, 'jump'),  qr{HOOK TRIGGER}i);
unlike($b->inject_input($conn_one, 'look'),  qr{HOOK TRIGGER}i);

$u->attack(
    attacker => $one,
    victim   => $mobiles{knight},
    damage   => $mobiles{knight}->current_strength,
    bodypart => 'head',
    message  => "%a deliver%s a mighty blow to %p %b!",
);

$conn_one->flush_output;
my @messages = split("\n", $conn_one->get_output);
is($messages[0], 'DEATH TRIGGER');

ok(!$mobiles{knight}->dead);

$u->attack(
    attacker => $one,
    victim   => $mobiles{monster},
    damage   => $mobiles{monster}->current_strength,
    bodypart => 'head',
    message  => "%a deliver%s a mighty blow to %p %b!",
);

$conn_one->flush_output;
@messages = grep { length($_) } split("\n", $conn_one->get_output);
is($messages[0], "You deliver a mighty blow to Monster's &+Rhead&N!");
is($messages[1], 'Monster falls to the ground.');
is($messages[2], 'MONSTER TRIGGER');

ok($mobiles{monster}->dead);

done_testing();
