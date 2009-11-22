#!/usr/bin/env perl
package AberMUD::Container;
use Moose;
use Bread::Board;
use Scalar::Util qw(weaken);

use AberMUD::Directory;
use AberMUD::Server;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;

use namespace::autoclean;

has container => (
    is      => 'rw',
    isa     => 'Bread::Board::Container',
    builder => '_build_container',
    handles => [qw(fetch)],
);

sub _build_container {
    my $self = shift;
#    my $container = weaken($self);
    my $container = $self; # FIXME dunno why weaken undefs this
    warn $self;

    my $c = container 'AberMUD' => as {
        service directory => (
            class     => 'AberMUD::Directory',
            lifecycle => 'Singleton',
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifecycle => 'Singleton',
            block     => sub {
                my $b = shift;
                AberMUD::Universe->new(
                    directory => $b->param('directory'),
                    nowhere_location  => AberMUD::Location->new(
                        id          => '__nowhere',
                        world_id    => '__nowhere@void',
                        title       => 'Nowhere',
                        description => 'You are nowhere...',
                    ),
                    spawn_player_code => sub {
                        my $self     = shift;
                        my $id       = shift;

                        my $player = $container->fetch('player')->get(
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

        service server => (
            class     => 'AberMUD::Server',
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
                depends_on('server'),
                depends_on('universe'),
            ]
        );

    };
}

1;

