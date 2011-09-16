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
use AberMUD::Backend::Test;

sub _build_controller_block {
    return sub {
        my ($self, $s) = @_;


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

    require AberMUD::Input::State::Game;
    my $p = $self->resolve(service => 'player');
    $p->input_state(
        [
            AberMUD::Input::State::Game->new(
                command_composite => $self->resolve(service => 'command_composite'),
            )
        ]
    );

    $p->name($name);
    $p->_join_game;
    $p->location($params{location});

    return $p;
}

sub config {
    my $self = shift;

    return $self->resolve(service => 'storage')->lookup('config');
}

1;

