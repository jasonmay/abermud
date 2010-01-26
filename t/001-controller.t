#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use AberMUD;
use AberMUD::Test::Container;
use AberMUD::Input::State::Login::Name;
use AberMUD::Input::State::Game;

my $c = AberMUD::Test::Container->new->container;

sub player_joins_game {
    my $p = $c->fetch('player')->get;
    $p->input_state([
        map {
            eval "require $_";
            $_->new(universe => $c->fetch('universe')->get)
        } qw(
        AberMUD::Input::State::Login::Name
        AberMUD::Input::State::Game)
    ]);

    return $p;
}

#sub player_logs_in {
#    my $p = shift;
#
#}

# test the test stuff first..
ok(!%{$c->fetch('universe')->get->players});
my $p1 = player_joins_game();
ok(%{$c->fetch('universe')->get->players});

my $p2 = player_joins_game();
my $p3 = player_joins_game();

is_deeply($c->fetch('universe')->get->players, +{1 => $p1, 2 => $p2, 3 => $p3});

my $beginning_state = $p1->input_state->[0];
my $response        = $beginning_state->run($p1 => "foo");

isnt($beginning_state, $p1->input_state->[0], 'change player input state');

is(
    $response, $p1->input_state->[0]->entry_message,
    'player is given response message'
);

