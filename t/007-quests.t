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
    container_args => {
        special => AberMUD::Special->new, # override to prevent ->load_plugins
    },
);

$c->special->hooks->{command} = [
    AberMUD::Special::Hook::Command->new(
        command_name => 'jump',
        before_block => sub { (1, "HOOK TRIGGER") },
    ),
];

my $u = $c->universe;
my $b = $c->controller->backend;

my ($one, $conn_one) = $b->new_player('playerone', special => $c->special);

like($b->inject_input($conn_one, 'jump'),  qr{HOOK TRIGGER}i);
unlike($b->inject_input($conn_one, 'look'),  qr{HOOK TRIGGER}i);

done_testing();
