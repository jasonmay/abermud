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
        AberMUD::Input::State::Game
        )
        ],
        universe => $universe,
    );
}

# TODO this is mostly player logic. put a lot of this in Player.pm
around '_response' => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $player = $self->universe->players->{$id};

    my $response = $self->$orig($id, @_);
    if (@{$player->input_state}
        && ref $player->input_state->[0] eq 'AberMUD::Input::State::Game') {

        if (!$player->in_game) { # all the "joining the universe world" logic
            $res_MSG->("player is not in game");
            if ($player->dir_player) {
                my $dir_player = $player->dir_player;
                $self->universe->broadcast(
                    sprintf "\n%s is back!\n", $player->name
                );

                # oh here's all my old attributes that you can't load
                for ($player->meta->get_all_attributes) {
                    if ($_->does('KiokuDB::DoNotSerialize')) {
                        my $attr = $_->accessor;
                        next if $attr eq 'id' or $attr eq 'io';
                        next if $attr eq 'dir_player';

                        $dir_player->$attr($player->$attr);
                    }
                }
                if ($dir_player->in_game) { #ghost that sucker
                    $dir_player->io->shutdown_output;
                    $dir_player->universe->players->{$player->id}
                        = $dir_player;
                    $dir_player->io($player->io);
                    $dir_player->id($player->id);
                }
                else {
                    $dir_player->materialize;
                    $dir_player->io($player->io);
                    $dir_player->id($player->id);
                }
            }

        }
        my $prompt = $player->prompt;
        return "$response\n$prompt";
    }
    return $response;
};

1;
