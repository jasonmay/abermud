#!/usr/bin/env perl
package AberMUD::Container::Role::Test;
use Moose::Role;
use Scalar::Util qw(weaken);

use Bread::Board;
use AberMUD::Storage;
use AberMUD::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;
use List::Util qw(max);

use namespace::autoclean;

requires qw(container new_universe);

has test_storage => (
    is  => 'ro',
    isa => 'AberMUD::Storage',
);

override _build_container => sub {
    my $self = shift;

    my $c = container 'AberMUD' => as {
        service storage => (
            class     => 'AberMUD::Storage',
            lifecycle => 'Singleton',
            block     => sub {
                weaken(my $weak_self = $self);
                $weak_self->test_storage || AberMUD::Storage->new
            },
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifecycle => 'Singleton',
            block     => sub {
                weaken(my $w = $self);
                $self->new_universe($w, @_)
            },
            dependencies => [
                depends_on('storage'),
                depends_on('controller'),
            ],
        );

        service player => (
            class => 'AberMUD::Player',
            block => sub {
                my $s      = shift;
                my $u      = $s->param('universe');
                my $max_id = max(keys %{ $u->players }) || 0;
                my $player = AberMUD::Player->new_with_traits(
                    traits    => ['AberMUD::Player::Role::Test'],
                    universe  => $u,
                    storage => $s->param('storage'),
                );

                $player->_join_server($max_id + 1);

                return $player;
            },
            dependencies => [
                depends_on('storage'),
                depends_on('universe'),
            ],
        );

        service controller => (
            class     => 'AberMUD::Controller',
            lifecycle => 'Singleton',
            block     => sub {
                my $s = shift;
                AberMUD::Controller->new_with_traits(
                    traits    => ['AberMUD::Controller::Role::Test'],
                    storage => $s->param('storage'),
                    universe  => $s->param('universe'),
                );
            },
            dependencies => [
                depends_on('storage'),
                depends_on('universe'),
            ]
        );

        service app => (
            class => 'AberMUD',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('storage'),
                depends_on('controller'),
                depends_on('universe'),
            ]
        );
    };
};

1;

