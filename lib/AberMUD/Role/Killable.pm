#!/usr/bin/env perl
package AberMUD::Role::Killable;
use Moose::Role;
use Moose::Util::TypeConstraints;
use AberMUD::Player;
#use AberMUD::Mobile;

has fighting => (
    is     => 'rw',
    does   => __PACKAGE__,
    traits => ['KiokuDB::DoNotSerialize'],
);

has sitting => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    traits => ['KiokuDB::DoNotSerialize'],
);

# the aber-convention for hitting power
has damage => (
    is => 'rw',
    isa => 'Num',
    default => 8,
);

has armor => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

# aber-convention for threshold of auto-flee
has wimpy => (
    is => 'rw',
    isa => 'Num',
    default => 25,
);

has current_strength => (
    is => 'rw',
    isa => 'Num',
    lazy_build => 1,
    traits => [ qw(KiokuDB::DoNotSerialize Number) ],
    handles => {reduce_strength => 'sub'},
);

sub _build_current_strength {
    my $self = shift;
    #warn "build";
    return $self->max_strength;
}

# aber-convention for the the base of your hit points
has basestrength => (
    is => 'rw',
    isa => 'Num',
    default => 40,
);

# aber-convention for the the level-based part of your hit points
has levelstrength => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

# aber-convention for the the base of your mana
has basemana => (
    is => 'rw',
    isa => 'Num',
    default => 40,
);

# aber-convention for the the level-based part of your mana
has levelmana => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

has gender => (
    is => 'rw',
    isa => subtype('Str' => where { !$_ or $_ eq 'Male' or $_ eq 'Female' }),
);

sub max_strength {
    my $self = shift;
    my $level = $self->can('level') ? $self->level : 0;

    return $self->basestrength + $self->levelstrength * $level;
}

sub show_inventory {
    my $self = shift;

    return undef unless $self->can('universe');

    my @objs = (
        grep { $_->can('held_by') && $_->held_by && $_->held_by == $self }
        @{ $self->universe->objects }
    ) or return undef;

    return "&+CCarrying:&*\n    " . join("\n    ", map { $_->name } @objs);
}

sub coverage {
    my $self = shift;
    return undef unless $self->can('universe');

    my $u = $self->universe;

    my @worn = grep {
        $_->wearable   && $_->getable
        && $_->held_by && $_->held_by == $self
        && $_->worn
    } $u->objects;

    my %covering = ();
    foreach my $worn (@worn) {
        next unless $worn->coverage;

        $covering{$_} = $worn
            for grep { $worn->coverage->{$_} }
                keys %{ $worn->coverage };
    }

    return %covering;
}

no Moose::Role;

1;

