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
    my $container = weaken($self);

    my $c = container 'AberMUD' => as {

        service directory => (
            class     => 'AberMUD::Directory',
            lifestyle => 'Singleton',
            block     => sub {
                AberMUD::Directory->new
            },
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifestyle => 'Singleton',
            block     => sub {
                my $b = shift;
                AberMUD::Universe->new(
                    directory         => $b->param('directory'),
                    nowhere_location  => AberMUD::Location->new(
                        id          => '__nowhere',
                        world_id    => '__nowhere@void',
                        title       => 'Nowhere',
                        description => 'You are nowhere...',
                    )
                );
            },
            dependencies => [
                depends_on('directory'),
            ],
        );

        service server => (
            class     => 'AberMUD::Server',
            lifestyle => 'Singleton',
            block     => sub {
                my $b = shift;
                AberMUD::Server->new(
                    universe => $b->param('universe')
                );
            },
            dependencies => [
                depends_on('directory'),
                depends_on('universe'),
            ]
        );

        service input_states => (
            class => 'AberMUD::Input::State',
            block => sub {
                my $b = shift;
            },
            dependencies => [
                depends_on('universe'),
            ]
        );

        service app => (
            class => 'AberMUD',
            lifestyle => 'Singleton',
            dependencies => [
                depends_on('directory'),
                depends_on('server'),
                depends_on('universe'),
            ]
        );

    };
}

1;

