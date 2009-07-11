#!/usr/bin/env perl
package AberMUD::Server;
use Moose;
extends 'MUD::Server';
use AberMUD::Player;
use AberMUD::Universe;

has player_data_path => (
    is  => 'rw',
    isa => 'Str',
    default => "$ENV{PWD}/data"
);

has '+universe' => (
    isa => 'AberMUD::Universe'
);

sub spawn_player {
    my $self = shift;
    my ($universe) = @_;
    return AberMUD::Player->new(
        prompt => sub {
            my $you = shift;
            my $name = $you->name;

            return
                "\e[1;36m$name\e[0m \e[1;33m\$\e[0m "
        },
        input_state => [$self->starting_state],
        universe => $universe
    );
}

1;
