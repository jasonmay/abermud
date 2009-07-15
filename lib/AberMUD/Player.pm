#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
extends 'MUD::Player';
use AberMUD::Server;
use POE::Wheel::ReadWrite;
use MooseX::Storage;
use Scalar::Util qw(weaken);
use Carp qw(cluck);
use DateTime;

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
    weak_ref  => 1,
    traits => ['DoNotSerialize'],
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
);

has 'confirmed_password' => (
    is        => 'rw',
    isa       => 'Str',
    traits => ['DoNotSerialize'],
);

has 'id' => (
    is        => 'rw',
    isa       => 'Int',
    traits => ['DoNotSerialize'],
);

has '+io' => (
    traits => ['DoNotSerialize'],
);

has '+input_state' => (
    traits => ['DoNotSerialize'],
);

has 'death_time' => (
    is => 'rw',
    isa => 'DateTime',
    traits => ['DoNotSerialize'],
);

# TODO Location Spells 

# the aber-convention for hitting power
has 'damage' => (
    is => 'rw',
    isa => 'Int',
    default => 8,
);

# invisibility up to N level
has 'visibility_level' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'level' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

has 'fighting' => (
    is => 'rw',
    isa => 'Boolean',
    default => 0,
    traits => ['DoNotSerialize'],
);

has 'sitting' => (
    is => 'rw',
    isa => 'Boolean',
    default => 0,
    traits => ['DoNotSerialize'],
);

has 'helping' => (
    is => 'rw',
    isa => 'Boolean',
    default => 0,
    traits => ['DoNotSerialize'],
);

has 'score' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

# aber-convention for threshold of auto-flee
has 'wimpy' => (
    is => 'rw',
    isa => 'Int',
    default => 25,
);

# aber-convention for the the base of your hit points
has 'basestrength' => (
    is => 'rw',
    isa => 'Int',
    default => 40,
);

# aber-convention for the the level-based part of your hit points
has 'levelstrength' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

# aber-convention for the the base of your mana
has 'basemana' => (
    is => 'rw',
    isa => 'Int',
    default => 40,
);

# aber-convention for the the level-based part of your mana
has 'levelmana' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

# highest level attained
has 'max_level' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

sub unshift_state {
    my $self = shift;
    unshift @{$self->input_state}, @_;
}

sub shift_state {
    my $self = shift;
    shift @{$self->input_state};
}

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

        $player->$_($self->$_) for qw/id universe input_state io/;

        $self->universe->players->{$self->id} = $player;
        weaken($self->universe->players_in_game->{lc $self->name} = $player);
        return $player;
    }

    return $self;
}

sub disconnect {
    my $self = shift;
    my $id = $self->id;
    $self->io->shutdown_output;
    delete $self->universe->players->{$self->id};
    delete $self->universe->players_in_game->{$self->name}
        if exists $self->universe->players_in_game->{$self->name};
    print STDERR "DISconnection [$id] :(\n\n";
}

1;
