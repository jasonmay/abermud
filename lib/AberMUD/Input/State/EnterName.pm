#!/usr/bin/env perl
package AberMUD::Input::State::EnterName;
use Moose;
extends 'MUD::Input::State';
use AberMUD::Input::State::Game;
use MUD::Input::State;
use Scalar::Util qw(weaken);

sub run {
    my $self = shift;
    my ($you, $name) = @_;
    $name = lc $name;

    push @{$you->input_state}, AberMUD::Input::State::Game->new;
    weaken($you->universe->players_in_game->{$name} = $you);

    $you->name($name);
    $you = $you->load_data;


    return "Your name is $name.\n" . $you->prompt;
}

1;
