#!/usr/bin/env perl
package AberMUD::Container;
use Moose;
use Bread::Board;
use Scalar::Util qw(weaken isweak);

use AberMUD::Directory;
use AberMUD::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Object::Role::Getable;
use AberMUD::Object::Role::Weapon;

use namespace::autoclean;

has container => (
    is         => 'rw',
    isa        => 'Bread::Board::Container',
    lazy_build => 1,
    builder    => '_build_container',
    handles    => [qw(fetch param)],
);

sub new_universe {
    my(@objs, @mobs);
    my $self = shift;
    my $container = shift;
    my $b = shift;
    weaken(my $w = $b);

    my $u = AberMUD::Universe->new(
        directory   => $w->param('directory'),
        _controller => $w->param('controller'),
        spawn_player_code => sub {
            my $self     = shift;
            my $id       = shift;
            #weaken(my $c = $container);
            my $player   = $container->fetch('player')->get(
                id          => $id,
                prompt      => "&+Y\$&* ",
                input_state => [
                map {
                    Class::MOP::load_class($_);
                    $_->new(
                        universe => $self,
                    )
                }
                qw(
                AberMUD::Input::State::Login::Name
                AberMUD::Input::State::Game
                )
                ],
            );

            return $player;
        }
    );


    my $start_loc
    = $w->param('directory')->lookup('location-start2')
    || $u->default_loc;

    my $m;

    $m = AberMUD::Mobile->new(
        name        => 'programmer',
        description => 'A programmer is looking at you.',
        location    => $start_loc,
        speed       => 20,
        universe    => $u,
    );

    my $o;

    $o = AberMUD::Object->new(
        name        => 'rock',
        description => 'There is a rock here.',
        location    => $start_loc,
        universe    => $u,
    );
    AberMUD::Object::Role::Getable->meta->apply($o);
    push @objs, $o;

    $o = AberMUD::Object->new(
        name        => 'sword',
        location    => $start_loc,
        description => 'There is a sword here.',
        universe    => $u,
    );
    AberMUD::Object::Role::Weapon->meta->apply($o);
    push @objs, $o;


    $u->objects([ @objs ]);
    $u->mobiles([ $m ]);

    return $u;
}

sub _build_container {
    my $container = shift;

    my $c = container 'AberMUD' => as {
        service directory => (
            class     => 'AberMUD::Directory',
            lifecycle => 'Singleton',
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifecycle => 'Singleton',
            block     => sub {
                weaken(my $w = $container);
                $container->new_universe($w, @_)
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
            class     => 'AberMUD::Controller',
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
}

1;

