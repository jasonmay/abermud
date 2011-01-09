#!/usr/bin/env perl
package AberMUD::Container::Role::Test;
use Moose::Role;

use Scalar::Util qw(weaken);
use List::Util qw(max);

use AberMUD::Storage;
use AberMUD::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;

use namespace::autoclean;

requires qw(container setup_controller);

sub _build_player_block {
    return sub {

        my ($self, $s) = @_;

        my $max_id = max(keys %{ $s->param('universe')->players }) || 0;
        my $player = AberMUD::Player->new_with_traits(
            traits    => ['AberMUD::Player::Role::Test'],
            %{ $s->params || {} },
        );

        $player->_join_server($max_id + 1);

        return $player;
    }

}

sub _build_controller_block {
    return sub {
        my ($self, $s) = @_;

        my $controller = AberMUD::Controller->new_with_traits(
            traits   => ['AberMUD::Controller::Role::Test'],
            storage  => $s->param('storage'),
            universe => $s->param('universe'),
        );

        $self->setup_controller($s, $controller);

        return $controller;
    }
}

sub _build_storage_block {
    return sub {
        return AberMUD::Storage->new(
            dsn        => 'hash',
            extra_args => [],
        );
    }
}

sub gen_player {
    my $self = shift;
    my $name = shift;
    my %params = @_;

    $params{location} ||= $self->storage_object->lookup('config')->location;

    require AberMUD::INput::State::Game;
    my $p = $self->resolve(service => 'player');
    $p->input_state(
        [
            AberMUD::Input::State::Game->new(
                special_composite => $self->resolve(service => 'special_composite'),
                command_composite => $self->resolve(service => 'command_composite'),
            )
        ]
    );

    $p->name($name);
    $p->_join_game;
    $p->location($params{location});

    return $p;
}

1;

