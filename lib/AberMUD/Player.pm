#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
use AberMUD::Server;
extends 'MUD::Player';
use MooseX::Storage;
use Scalar::Util qw(weaken);
use Carp qw(cluck);

=head1 NAME

AberMUD::Player - AberMUD Player class for playing

=head1 SYNOPSIS

    my $player = AberMUD::Player->new;

    ...

    $player->save;

=head1 DESCRIPTION

AberMUD's player system is very straightforward. Each player has a connection
to the server. A player's location and inventory does not stay on that person
when he leaves the game. 

=cut

with Storage(format => 'YAML', 'io' => 'File');

has 'prompt' => (
    is  => 'rw',
    isa => 'Str'
);

has 'universe' => (
    is        => 'rw',
    isa       => 'AberMUD::Universe',
#    required  => 1,
    weak_ref  => 1,
    metaclass => 'DoNotSerialize',
);

has 'id' => (
    is        => 'rw',
    isa       => 'Int',
#    required  => 1,
    metaclass => 'DoNotSerialize',
);

has '+input_state' => (
    metaclass => 'DoNotSerialize',
);

sub in_game {
    my $self = shift;
    return exists($self->universe->players_in_game->{$self->name});
}

sub is_saved {
    my $self = shift;
    return -e('data/players/' . lc $self->name . '.yaml');
}

sub save_data {
    my $self = shift;

    cluck "Trying to call save when the player is not in-game"
        unless $self->in_game;

    $self->store('data/players/' . lc $self->name . '.yaml');
}

sub load_data {
    my $self = shift;

    my $load_file = 'data/players/' . lc $self->name . '.yaml';

    if ($self->is_saved) {
        my $player = AberMUD::Player->load($load_file);

        for (qw/id universe input_state/) {
            $player->$_($self->$_);
        }

        $self->universe->players->{$self->id} = $player;
        weaken($self->universe->players_in_game->{lc $self->name} = $player);
        return $player;
    }

    return $self;
}

sub disconnect {

}

1;
