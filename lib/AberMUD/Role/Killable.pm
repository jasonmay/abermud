#!/usr/bin/env perl
package AberMUD::Role::Killable;
use Moose::Role;
use Moose::Util::TypeConstraints;
use AberMUD::Player;
use AberMUD::Location::Util qw(directions);

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
    is         => 'rw',
    isa        => 'Int',
    lazy_build => 1,
    traits     => [ qw(KiokuDB::DoNotSerialize) ],
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
        $self->universe->get_objects
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
    } $u->get_objects;

    my %covering = ();
    foreach my $worn (@worn) {
        next unless $worn->coverage;

        $covering{$_} = $worn
            for grep { $worn->coverage->{$_} }
                keys %{ $worn->coverage };
    }

    return %covering;
}

sub carrying {
    my $self = shift;

    return grep {
        $_->can('held_by') and $_->held_by and $_->held_by == $self
    } $self->universe->get_objects;
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

foreach my $direction ( directions() ) {
    __PACKAGE__->meta->add_method("go_$direction" =>
        sub {
            my $self = shift;

            my $destination = $self->${\"can_go_$direction"}
                or return undef;

            $self->say(
                sprintf("\n%s goes %s\n", $self->name, $direction),
                except => $self,
            );

            $self->location($destination);

            my %opp_dir = (
                east  => 'the west',
                west  => 'the east',
                north => 'the south',
                south => 'the north',
                up    => 'below',
                down  => 'above',
            );

            $self->say(
                sprintf(
                    "\n%s arrives from %s\n",
                    $self->name, $opp_dir{$direction}
                ),
                except => $self,
            );

            return $destination;
        }
    );
}

sub formatted_name {
    my $self = shift;
    return $self->name;
}

no Moose::Role;

1;

