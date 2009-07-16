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

around '_response' => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $player = $self->universe->players->{$id};

    my $response = $self->$orig($id, @_);
    if (@{$player->input_state}
        && ref $player->input_state->[0] eq 'AberMUD::Input::State::Game') {
        $player->materialize;
        $player->save_data;
        my $prompt = $player->prompt;
        return "$response\n$prompt";
    }
    return $response;
};

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
                AberMUD::Input::State::Game
            )
        ],
        universe => $universe,
    );
}

1;
