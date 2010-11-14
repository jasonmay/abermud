#!/usr/bin/env perl
package AberMUD::Player::Role::InGame;
use Moose::Role;

use DateTime;

use AberMUD::Location;
use AberMUD::Data::Levels;

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
    traits => ['KiokuDB::DoNotSerialize'],
);

sub level {
    my $self = shift;

    my $levelpoints = AberMUD::Data::Levels->level_points;

    return 0 if $self->score < 0;

    for (my $i = 1; $i < @$levelpoints; ++$i) {
        if ($self->score < $levelpoints->[$i]) {
            return $i - 1;
        }
    }
}

no Moose::Role;

1;

