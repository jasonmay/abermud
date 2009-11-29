#!/usr/bin/env perl
package AberMUD::Player::Role::InGame;
use Moose::Role;

use AberMUD::Location;
use DateTime;

has 'location' => (
    is => 'rw',
    isa => 'AberMUD::Location',
    traits => ['KiokuDB::DoNotSerialize'],
    handles => {
        map {
            ("can_go_$_" => "has_$_")
        } @{AberMUD::Location->directions}
    },
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

no Moose::Role;

1;

