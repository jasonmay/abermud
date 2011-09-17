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

has class => (
    is => 'rw',
    isa => 'Str',
    default => 'Warrior',
);

has completed_quests => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
);

sub complete_quest {
    my $self  = shift;
    my $quest = shift;

    my $exp_award = 3000;

    my $output = "Congratulations! You've completed the &+C$quest&* quest!\n";

    if (!$self->completed_quests->{$quest}) {
        $output .=
            q[Since this is your first time completing it, you have been ] .
            qq[awarded &+Y$exp_award&* experience points!\n];

        $self->change_score($exp_award);
    };

    $self->append_output_buffer($output);
    $self->completed_quests->{$quest}++;
    $self->save_data;
}

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

sub carrying_key {
    my $self = shift;

    my @available = grep
                    { $_->key && $_->in_direct_possession }
                    $self->carrying_loosely;

    return @available ? $available[0] : undef;
}

no Moose::Role;

1;

