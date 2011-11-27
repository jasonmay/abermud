#!/usr/bin/env perl
package AberMUD::Role::Killable;
use Moose::Role;
use Moose::Util::TypeConstraints;

use KiokuDB::Util 'set';

use Array::IntSpan;
use List::Util qw(first);

use AberMUD::Player;
use AberMUD::Location::Util qw(directions);
use AberMUD::Object::Util qw(bodyparts);
use AberMUD::Messages;


requires 'death';

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

sub take_damage {
    my $self           = shift;
    my $universe       = shift;
    my $damage         = shift;
    my $predeath_block = shift;

    my $prev_strength = $self->current_strength;
    my $new_strength  = $self->current_strength - $damage;

    $new_strength = 0 if $new_strength < 0;

    $self->current_strength($new_strength)
        if $self->current_strength;

    if ($self->fighting and $self->fighting->isa('AberMUD::Player')) {
        my $xp = $prev_strength - $new_strength;
        $universe->change_score($self->fighting, $xp);
    }

    $predeath_block->($self, $damage) if $predeath_block;

    if ($self->current_strength <= 0) {
        $self->death(universe => $universe);
    }
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

sub attack {
    my $self = shift;
    my %args = @_;

    my $universe = $args{universe};

    my $victim = $self->fighting
        or return;

    my $bodypart = ( bodyparts() )[ rand scalar( bodyparts() ) ];

    my $damage = int rand($self->total_damage);

    my $perc = $damage * 100 / $self->total_damage;

    my $spans = Array::IntSpan->new(
        [(0, 0) => 'futile'],
        [(1, 33) => 'weak'],
        [(34, 66) => 'med'],
        [(67, 100) => 'strong'],
    );

    my $damage_level = $spans->lookup(int $perc);

    # keep reading as Shit_type and is making me laugh
    my $hit_type = $self->wielding ? 'WeaponHit' : 'BareHit';

    my %hits = %{ AberMUD::Messages->$hit_type };

    my @messages = @{ $hits{$damage_level} };

    my $message = $messages[rand @messages];

    my %final_messages = (
        map {
            $_ => AberMUD::Messages::format_fight_message(
                $message,
                attacker    => $self,
                victim      => $self->fighting,
                bodypart    => $bodypart,
                perspective => $_,
            ) . "\n";
        } qw(attacker victim bystander)
    );

    $self->append_output_buffer($final_messages{attacker})
        if $self->isa('AberMUD::Player');

    $victim->take_damage(
        $universe, $damage, sub {
            my $self = shift;

            # send the (potentially) final message right
            # before death. this displays the prompt
            # at the right time and stuff
            $victim->append_output_buffer($final_messages{victim})
                if $victim->isa('AberMUD::Player');
        }
    );


    $self->say(
        $final_messages{bystander},
        except => [$self, $victim],
    );

    # if this attack killed the victim
    if ($victim->dead) {
        $self->say(
            sprintf(
                qq[%s falls to the ground.\n],
                $victim->formatted_name,
            ),
            except => [$victim],
        );
    }
}

before death => sub {
    my $self = shift;

    if (my $opponent = $self->fighting) {
        $self->stop_fighting;
        $opponent->stop_fighting;
    }
    $self->dead(1);
};

no Moose::Role;

1;

