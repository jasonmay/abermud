#!/usr/bin/env perl
package AberMUD::Test::Container;
use Moose;
extends 'AberMUD::Container';

use Bread::Board;
use Scalar::Util qw(weaken isweak);

use AberMUD::Directory;
use AberMUD::Test::Controller;
use AberMUD::Universe;
use AberMUD::Test::Player;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Object::Role::Getable;
use AberMUD::Object::Role::Weapon;
use List::Util qw(max);

use namespace::autoclean;

override _build_container => sub {
    my $self = shift;

    my $c = container 'AberMUD' => as {
        service directory => (
            class     => 'AberMUD::Directory',
            lifecycle => 'Singleton',
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifecycle => 'Singleton',
            block     => sub {
                weaken(my $w = $self);
                $self->new_universe($w, @_)
            },
            dependencies => [
                depends_on('directory'),
                depends_on('controller'),
            ],
        );

        service player => (
            class => 'AberMUD::Test::Player',
            block => sub {
                my $s      = shift;
                my $u      = $s->param('universe');
                my $id     = (
                    max(keys %{$u->players}) || 0
                ) + 1;
                my $player = AberMUD::Test::Player->new(
                    universe  => $u,
                    directory => $s->param('directory'),
                );

                $player->_join_server($id);

                return $player;
            },
            dependencies => [
                depends_on('directory'),
                depends_on('universe'),
            ],
        );

        service controller => (
            class     => 'AberMUD::Test::Controller',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('directory'),
                depends_on('universe'),
            ]
        );

        service app => (
            class => 'AberMUD',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('directory'),
                depends_on('controller'),
                depends_on('universe'),
            ]
        );
    };
};

1;

