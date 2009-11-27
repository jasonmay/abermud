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
                weaken(my $w = $b);
                AberMUD::Universe->new(
                    directory => $w->param('directory'),
                    _controller => $w->param('controller'),
                    spawn_player_code => sub {
                        my $self     = shift;
                        my $id       = shift;
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

