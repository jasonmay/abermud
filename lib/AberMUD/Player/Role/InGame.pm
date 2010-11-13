#!/usr/bin/env perl
package AberMUD::Player::Role::InGame;
use Moose::Role;

use AberMUD::Location;
use DateTime;

with qw(AberMUD::Role::InGame);

has death_time => (
    is => 'rw',
    isa => 'DateTime',
    default => sub { DateTime->now },
    traits => ['KiokuDB::DoNotSerialize'],
);

# invisibility up to N level
has visibility_level => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

has level => (
    is => 'rw',
    isa => 'Num',
    default => 1,
);

has helping => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    traits => ['KiokuDB::DoNotSerialize'],
);

has score => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

# highest level attained
has max_level => (
    is => 'rw',
    isa => 'Num',
    default => 1,
);

has following => (
    is   => 'rw',
    does => 'AberMUD::Role::Killable',
);

no Moose::Role;

1;

