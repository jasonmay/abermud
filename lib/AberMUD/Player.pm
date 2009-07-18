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
use KiokuDB;

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
    traits => ['KiokuDB::DoNotSerialize'],
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
);

has 'id' => (
    is        => 'rw',
    isa       => 'Int',
    traits => ['KiokuDB::DoNotSerialize'],
);

has '+io' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

has '+input_state' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

has 'death_time' => (
    is => 'rw',
    isa => 'DateTime',
    default => sub { DateTime->now },
    traits => ['KiokuDB::DoNotSerialize'],
);

# TODO Location, Spells 

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
    isa => 'Bool',
    default => 0,
    traits => ['KiokuDB::DoNotSerialize'],
);

has 'sitting' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    traits => ['KiokuDB::DoNotSerialize'],
);

has 'helping' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    traits => ['KiokuDB::DoNotSerialize'],
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
    return $self->universe->directory->lookup($self->name);
}

sub save_data {
    my $self = shift;

    if (!$self->in_game) {
        cluck "Trying to call save when the player is not in-game";
        return;
    }

    if ($self->universe->directory->lookup(lc $self->name)) {
        $self->universe->directory->store($self);
    }
    else {
        $self->universe->directory->store(lc $self->name => $self);
    }
}

sub load_data {
    my $self = shift;

    if ($self->is_saved) {
        my $player = $self->universe->directory->lookup(lc $self->name);
        for ($player->meta->get_all_attributes) {
            if ($_->does('KiokuDB::DoNotSerialize')) {
                my $attr = $_->accessor;
                $player->$attr($self->$attr)
            }
        }

        $self->universe->players->{$self->id} = $player;
        return $player;
    }

    return $self;
}

sub materialize {
    my $self = shift;
    warn "!!! " . $self->name;
    weaken($self->universe->players_in_game->{lc $self->name} = $self)
        unless exists $self->universe->players_in_game->{lc $self->name};
}

sub dematerialize {
    my $self = shift;
    delete $self->universe->players_in_game->{lc $self->name};
}


sub disconnect {
    my $self = shift;
    my $id = $self->id;
    $self->io->shutdown_output;
    delete $self->universe->players->{$self->id};

    if (exists $self->universe->players_in_game->{$self->name}) {
        $self->dematerialize;
        warn 'disconnect ' .
            join ' ' => keys %{$self->universe->players_in_game};
        $self->universe->broadcast($self->name . " disconnected.\n");
        $self->shift_state;
        print STDERR "Disconnection [$id] :(\n\n";
    }
}

1;
