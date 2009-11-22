#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
extends 'MUD::Player';
use AberMUD::Server;
use POE::Wheel::ReadWrite;
use MooseX::Storage;
use Scalar::Util qw(weaken);
use Carp qw(cluck);
use AberMUD::Location;
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
    required  => 1,
    weak_ref  => 1,
    traits => ['KiokuDB::DoNotSerialize'],
);

has 'directory' => (
    is        => 'rw',
    isa       => 'AberMUD::Directory',
    required  => 1,
    weak_ref  => 1,
    traits => ['KiokuDB::DoNotSerialize'],
);

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
    isa    => 'ArrayRef[AberMUD::Input::State]',
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

foreach my $direction (@{AberMUD::Location->directions}) {
    __PACKAGE__->meta->add_method("go_$direction" =>
        sub {
            my $self = shift;

            return "You can't go that way."
                unless $self->${\"can_go_$direction"};

            $self->location($self->location->$direction);

            return $self->look;
        }
    );
}

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

    if ($self->directory->player_lookup($self->name)) {
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
    $self->sys_message(
    join ' ' =>
        map { my $ref = ref; $ref =~ s/AberMUD::Input::State:://; $ref }
        @{$self->input_states}
    );
}

sub _copy_unserializable_data {
    my $self = shift;
    my $player = shift;

    for ($player->meta->get_all_attributes) {
        if ($_->does('KiokuDB::DoNotSerialize')) {
            my $attr = $_->accessor;
            next if $attr eq 'id' or $attr eq 'io';
            next if $attr eq 'dir_player';
            $self->$attr($player->$attr) if defined $player->$attr;
        }
    }
}

sub _copy_socket_data {
    my $self = shift;
    my $player = shift;

    $self->id($player->id) if defined $player->id;
    $self->io($player->io) if defined $player->io;
}

sub _join_game {
    my $self = shift;

    if (!$self->universe) {
        warn "No universe!";
        return;
    }

    if (!$self->universe->players_in_game) {
        warn "players_in_game undefined!";
        return;
    }
    weaken( $self->universe->players_in_game->{lc $self->name} = $self );
}

sub _join_server {
    my $self = shift;

    if (!$self->universe) {
        warn "No universe!";
        return;
    }

    if (!$self->universe->players) {
        warn "universe->players undefined!";
        return;
    }

    weaken( $self->universe->players->{$self->id} = $self );
}

# game stuff
sub setup {
    my $self = shift;
    my $location = $self->universe->directory->lookup('location-start2');
#    die "No location found in directory" unless defined $location;
    $self->location($location || $self->universe->nowhere_location);
}

sub materialize {
    my $self = shift;
    my $id = $self->id;
    if (!$self->in_game) {
        $self->sys_message("materialize");
        my $dir_player = $self->dir_player;
        if ($dir_player) {
            $self->universe->broadcast(
                sprintf "%s is &+Wback&*!", $self->name
            );

            $dir_player->_copy_unserializable_data($self);

            if ($dir_player->in_game) {
                $dir_player->io->shutdown_output;
            }
            else {
                $dir_player->_join_game;
                $dir_player->setup;
            }
            $dir_player->_copy_socket_data($self);
            $dir_player->_join_server;
        }
        else {
            $self->_join_game;
            $self->save_data;
            $self->setup;
            $self->universe->broadcast(
                sprintf "\n%s has &+Yjoined&*!\n", $self->name
            );
        }
    }
}

sub dematerialize {
    my $self = shift;
    delete $self->universe->players_in_game->{lc $self->name};
}

sub look {
    my $self = shift;
    my $loc = shift || $self->location;
    my $output = $loc->title . "\n";

    $output .= $loc->description;
    foreach my $player (values %{$self->universe->players_in_game}) {
        next if $player == $self;
        $output .= ucfirst($player->name) . " is standing here.\n"
            if $player->location == $self->location;
    }

    $output .= "\n" . $loc->show_exits;

    return $output;
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
