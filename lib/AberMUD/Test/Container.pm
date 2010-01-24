#!/usr/bin/env perl
package AberMUD::Test::Container;
use Moose;
extends 'AberMUD::Container';

use Bread::Board;
use Scalar::Util qw(weaken isweak);

use AberMUD::Directory;
use AberMUD::Test::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Object::Role::Getable;
use AberMUD::Object::Role::Weapon;

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
            class => 'AberMUD::Player',
            dependencies => [
                depends_on('directory'),
                depends_on('universe'),
            ],
            parameters => {
                id          => { isa => 'Int' },
                prompt      => { isa => 'Str' },
                input_state => { isa => 'ArrayRef' },
            },
        );

        service controller => (
            class     => 'AberMUD::Test::Controller',
            lifecycle => 'Singleton',
            block     => sub {
                my $s = shift;

                no warnings 'redefine';
                my $controller = AberMUD::Test::Controller->new(
                    universe  => $s->param('universe'),
                    directory => $s->param('directory'),
                );
            },
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

