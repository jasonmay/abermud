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
    is      => 'rw',
    isa     => 'Bread::Board::Container',
    builder => '_build_container',
    handles => [qw(fetch)],
);

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
                my(@objs, @mobs);
                my $b = shift;
                weaken(my $w = $b);
                my $start_loc
                    = $w->param('directory')->lookup('location-start2');

                my $m;

                $m = AberMUD::Mobile->new(
                    name        => 'programmer',
                    description => 'A programmer is looking at you.',
                    location    => $start_loc,
                    speed       => 20,
                );

                my $o;

                $o = AberMUD::Object->new(
                    name        => 'rock',
                    description => 'There is a rock here.',
                    location    => $start_loc,
                );
                AberMUD::Object::Role::Getable->meta->apply($o);
                push @objs, $o;

                $o = AberMUD::Object->new(
                    name        => 'sword',
                    location    => $start_loc,
                    description => 'There is a sword here.',
                );
                AberMUD::Object::Role::Weapon->meta->apply($o);
                push @objs, $o;

                AberMUD::Universe->new(
                    directory   => $w->param('directory'),
                    _controller => $w->param('controller'),
                    objects     => [ @objs ],
                    mobiles     => [ $m    ],
                    spawn_player_code => sub {
                        my $self     = shift;
                        my $id       = shift;
                        weaken(my $c = $container);
                        my $player   = $c->fetch('player')->get(
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

