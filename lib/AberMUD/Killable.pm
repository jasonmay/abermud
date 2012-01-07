#!/usr/bin/env perl
package AberMUD::Killable;
use Moose;
use Moose::Util::TypeConstraints;

use KiokuDB::Util 'set';

use Array::IntSpan;
use List::Util qw(first);

use AberMUD::Location::Util qw(directions);
use AberMUD::Object::Util qw(bodyparts);

has fighting => (
    is      => 'rw',
    does    => __PACKAGE__,
    traits  => ['KiokuDB::DoNotSerialize'],
    clearer => 'stop_fighting',
);

has sitting => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    traits  => ['KiokuDB::DoNotSerialize'],
);

# the aber-convention for hitting power
has damage => (
    is      => 'rw',
    isa     => 'Num',
    default => 8,
);

has armor => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

# aber-convention for threshold of auto-flee
has wimpy => (
    is      => 'rw',
    isa     => 'Num',
    default => 25,
);

has current_strength => (
    is         => 'rw',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_current_strength {
    my $self = shift;
    #warn "build";
    return $self->max_strength;
}

# aber-convention for the the base of your hit points
has basestrength => (
    is      => 'rw',
    isa     => 'Num',
    default => 40,
);

# aber-convention for the the level-based part of your hit points
has levelstrength => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

# aber-convention for the the base of your mana
has basemana => (
    is      => 'rw',
    isa     => 'Num',
    default => 40,
);

# aber-convention for the the level-based part of your mana
has levelmana => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has gender => (
    is  => 'rw',
    isa => subtype('Str' => where { !$_ or $_ eq 'Male' or $_ eq 'Female' }),
);

has dead => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has _carrying => (
    is      => 'ro',
    lazy    => 1,
    default => sub { set() },
    handles => {carrying => 'members'},
);

has wielding => (
    is      => 'rw',
    isa     => 'AberMUD::Object',
    clearer => '_stop_wielding',
);

sub max_strength {
    my $self = shift;
    my $level = $self->can('level') ? $self->level : 0;

    return $self->basestrength + $self->levelstrength * $level;
}

sub total_damage {
    my $self = shift;

    my $damage = $self->damage;

    if ($self->wielding) {
        $damage += $self->wielding->damage;
    }

    return $damage;
}

sub reduce_strength {
    my $self = shift;
    my $amount = shift;

    my $prev_strength = $self->current_strength;
    my $new_strength  = $self->current_strength - $amount;
    $self->current_strength($new_strength > 0 ? $new_strength : 0);

    return $prev_strength;
}

sub show_inventory {
    my $self = shift;

    return undef unless $self->can('universe');

    my @objs = (
        grep { $_->can('held_by') && $_->held_by && $_->held_by == $self }
        $self->universe->get_objects
    ) or return undef;

    return "&+CCarrying:&*\n    " . join("\n    ", map { $_->name } @objs);
}

sub coverage {
    my $self = shift;

    my @worn = grep {
        $_->wearable   && $_->getable
        && $_->held_by && $_->held_by == $self
        && $_->worn
    } $self->carrying;

    my %covering = ();
    foreach my $worn (@worn) {
        next unless $worn->coverage;

        $covering{$_} = $worn
            for grep { $worn->coverage->{$_} }
                keys %{ $worn->coverage };
    }

    return %covering;
}

sub carrying_loosely {
    my $self = shift;

    return grep {
        not
        ($_->can('wielded_by') and $_->wielded_by and $_->wielded_by == $self)

        and not
        ($_->can('worn_by') and $_->worn_by and $_->worn_by == $self)
    } $self->carrying;
}

sub take {
    my $self = shift;
    my ($object) = @_;

    $self->_carrying->insert($object);
    $object->held_by($self);
}

sub drop {
    my $self = shift;
    my ($object) = @_;

    $self->_carrying->remove($object);
    $object->_stop_being_held;

    $self->location->objects_in_room->insert($object);
}

sub formatted_name {
    my $self = shift;
    return $self->name;
}

sub start_fighting {
    my $self = shift;
    my $victim = shift;
    $self->fighting($victim);
    $victim->fighting($self);
}

sub death {
    my $self = shift;

    if (my $opponent = $self->fighting) {
        $self->stop_fighting;
        $opponent->stop_fighting;
    }
    $self->dead(1);
};

no Moose;

1;

