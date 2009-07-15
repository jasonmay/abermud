#!/usr/bin/env perl
package AberMUD::Server;
use Moose;
extends 'MUD::Server';
use AberMUD::Player;
use AberMUD::Universe;

has player_data_path => (
    is  => 'rw',
    isa => 'Str',
    default => "$ENV{PWD}/data"
);

has '+universe' => (
    isa => 'AberMUD::Universe'
);

sub spawn_player {
    my $self     = shift;
    my $id       = shift;
    my $universe = shift;
    return AberMUD::Player->new(
        id => $id,
        prompt => "\e[1;33m\$\e[0m ",
        input_state => [
            map { eval "require $_"; $_->new }
            qw(
                AberMUD::Input::State::Login::Name
                AberMUD::Input::State::Login::Password
                AberMUD::Input::State::Game
            )
        ],
        universe => $universe,
    );
}

1;
