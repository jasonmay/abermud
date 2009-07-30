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

has 'location' => (
    is => 'rw',
    isa => 'AberMUD::Location',
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

has 'dir_player' => (
    is        => 'rw',
    isa       => 'AberMUD::Player',
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
    # one at a time to help with debug messages
    return 0 unless $self->universe;
    return 0 unless exists($self->universe->players_in_game->{$self->name});
    return $self->universe->players_in_game->{$self->name}->id == $self->id;
}

sub is_saved {
    my $self = shift;
    return $self->universe->directory->lookup('player-' . lc $self->name);
}

sub save_data {
    my $self = shift;

    if (!$self->in_game) {
        cluck "Trying to call save when the player is not in-game";
        return;
    }

    if ($self->universe->player_lookup($self->name)) {
        $self->universe->directory->update($self);
    }
    else {
        $self->universe->directory->store('player-' . lc $self->name => $self);
    }
}

sub load_data {
    my $self = shift;

    if ($self->is_saved) {
        my $player
            = $self->universe->directory->lookup('player-' . lc $self->name);
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

sub sys_message {
    my $self = shift;
    return unless $self->universe;
    $self->universe->abermud_message(@_);
}

sub dump_states {
    my $self = shift;
    $self->sys_message(join ' ' => map { ref } @{$self->input_states});
}

sub _map_unserializables {
    my $self = shift;
    my $player = shift;

    for ($player->meta->get_all_attributes) {
        if ($_->does('KiokuDB::DoNotSerialize')) {
            my $attr = $_->accessor;
            next if $attr eq 'id' or $attr eq 'io';
            next if $attr eq 'dir_player';
            $self->$attr($player->$attr);
        }
    }
}

# game stuff
sub setup {
    my $self = shift;
    my $location = $self->universe->directory->lookup('location-start2');
    $self->sys_message("locatino set TYPOS");
    $self->location($location);
}

sub materialize {
    my $self = shift;
    my $id = $self->id;
    if (!$self->in_game) {
        $self->sys_message("materialize");
        if ($self->dir_player) {
            my $dir_player = $self->dir_player;
            $self->universe->broadcast(
                sprintf "\n%s is back!\n", $self->name
            );

            $dir_player->_map_unserializables($self);
            $self->dump_states;

            if ($dir_player->in_game) {
                $dir_player->io->shutdown_output;
                weaken($dir_player->universe->players->{$self->id}
                    = $dir_player);
            }
            else {
                weaken(
                    $dir_player->universe->players_in_game->{lc $self->name}
                    = $dir_player
                );
            }
            $dir_player->io($self->io);
            $dir_player->id($self->id);
        }
        else {
            weaken(
                $self->universe->players_in_game->{lc $self->name}
                = $self
            );
            $self->save_data;
            $self->universe->broadcast(
                sprintf "\n%s has joined!\n", $self->name
            );
        }
    }
}

sub dematerialize {
    my $self = shift;
    delete $self->universe->players_in_game->{lc $self->name};
}

around 'disconnect' => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;
    my $id = $self->id;

    $self->$orig(@_);
    delete $self->universe->players->{$self->id};

    if (exists $self->universe->players_in_game->{$self->name}) {
        $self->dematerialize;

        $self->universe->broadcast($self->name . " disconnected.\n")
        unless $args{'silent'};

        $self->shift_state;
    }
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
