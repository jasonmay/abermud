#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
use namespace::autoclean;
extends 'MUD::Player';

#use AberMUD::Controller;
use AberMUD::Location;

use POE::Wheel::ReadWrite;
use Scalar::Util qw(weaken);
use Carp qw(cluck);
use DateTime;
use KiokuDB;
use List::MoreUtils qw(first_value);
use DDS;

=head1 NAME

AberMUD::Player - AberMUD Player class for playing

=head1 SYNOPSIS

    my $player = AberMUD::Player->new;

    ...

    $player->save;

=head1 DESCRIPTION

XXX

AberMUD's player system is very straightforward. Each player has a connection
to the server. A player's location and inventory does not stay on that person
when he leaves the game.

=cut

with qw(
    AberMUD::Player::Role::InGame
    AberMUD::Role::Killable
);

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

has 'password' => (
    is => 'rw',
    isa => 'Str',
);

sub id {
    my $self = shift;
    my $p = $self->universe->players || {};

    return first_value { $p->{$_} == $self } keys %$p;
}

has 'dir_player' => (
    is        => 'rw',
    isa       => 'AberMUD::Player',
    traits => ['KiokuDB::DoNotSerialize'],
);

has '+input_state' => (
    isa    => 'ArrayRef[AberMUD::Input::State]',
    traits => ['KiokuDB::DoNotSerialize'],
);

foreach my $direction (@{AberMUD::Location->directions}) {
    __PACKAGE__->meta->add_method("go_$direction" =>
        sub {
            my $self = shift;

            return "You can't go that way.\n"
                unless $self->${\"can_go_$direction"};

            my @players = values %{ $self->universe->players_in_game };

            $self->say("\n" . $self->name . " goes " . $direction . "\n");

            $self->location($self->location->$direction);

            my %opp_dir = (
                east  => 'the west',
                west  => 'the east',
                north => 'the south',
                south => 'the north',
                up    => 'below',
                down  => 'above',
            );

            $self->say("\n" . $self->name . " arrives from the " . $opp_dir{$direction} . "\n");

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
    my $u    = $self->universe;

    return 0 unless $u;
    return 0 unless exists($u->players_in_game->{$self->name});
    return $u->players_in_game->{$self->name} == $self;
}

sub is_saved {
    my $self = shift;
    return $self->universe->directory->lookup('player-' . lc $self->name);
}

sub save_data {
    my $self = shift;
    my %args = @_;

    my $u    = $self->universe;

    if (!$self->in_game) {
        cluck "Trying to call save when the player is not in-game";
        return;
    }

    if ($self->directory->player_lookup($self->name)) {
        $u->directory->update($self);
    }
    else {
        $u->directory->store('player-' . lc $self->name => $self);
    }
}

sub load_data {
    my $self = shift;
    my $u    = $self->universe;

    if ($self->is_saved) {
        my $player
            = $u->directory->lookup('player-' . lc $self->name);
        for ($player->meta->get_all_attributes) {
            if ($_->does('KiokuDB::DoNotSerialize')) {
                my $attr = $_->accessor;
                $player->$attr($self->$attr)
            }
        }
        $u->players->{$self->id} = $player;
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
            next if $attr eq 'dir_player';
            $self->$attr($player->$attr) if defined $player->$attr;
        }
    }
}

sub _join_game {
    my $self = shift;
    my $u = $self->universe;

    if (!$u) {
        warn "No universe!";
        return;
    }

    if (!$u->players_in_game) {
        warn "players_in_game undefined!";
        return;
    }
    $u->players_in_game->{lc $self->name} = $self;
}

sub _join_server {
    my $self = shift;
    my $id   = shift;
    my $u    = $self->universe;

    if (!$u) {
        warn "No universe!";
        return;
    }

    if (!$u->players) {
        warn "universe->players undefined!";
        return;
    }

    if (!$id && !$self->id) {
        warn "undefined id";
        return;
    }

    $u->players->{$id || $self->id} = $self;
}

# game stuff
sub setup {
    my $self = shift;
    my $location = $self->universe->directory->lookup('location-start2');
    warn "No location found in directory" unless defined $location;
    $self->location($location || $self->universe->nowhere_location);
}

sub materialize {
    my $self = shift;
    my $u    = $self->universe;

    return if $self->in_game;

    $self->sys_message("materialize");

    my $m_player = $self->dir_player || $self;

    if ($m_player != $self && $m_player->in_game) {
        $u->_controller->force_disconnect($m_player->id, ghost => 1);
        $u->players->{$self->id} = delete $u->players->{$m_player->id};
        return;
    }

    if (!$m_player->in_game) {
        $m_player->_copy_unserializable_data($self);
        $m_player->_join_server($self->id);
    }

    $m_player->_join_game;
    $m_player->save_data if $m_player == $self;
    $m_player->setup;
}

sub dematerialize {
    my $self = shift;
    delete $self->universe->players_in_game->{lc $self->name};
}

sub look {
    my $self   = shift;
    my $loc    = shift || $self->location;

    my $output = sprintf(
        "&+M%s&* &+B[&+C%s@%s&+B]&* (%s)\n",
        $loc->title,
        $loc->id,
        $loc->zone->name,
        $loc->world_id
    );

    $output .= $loc->description;

    foreach my $mobile (@{$self->universe->mobiles || []}) {
        $output .= $mobile->description . "\n"
            if $mobile->location == $self->location;
    }

    foreach my $player (values %{$self->universe->players_in_game}) {
        next if $player == $self;
        $output .= ucfirst($player->name) . " is standing here.\n"
            if $player->location == $self->location;
    }

    $output .= sprintf("%s\n", $_->description)
        for grep {
            $_->location == $loc
        } @{$self->universe->objects};

    $output .= "\n" . $loc->show_exits;

    return $output;
}

sub send {
    my $self    = shift;
    my $message = shift;
    my %args    = @_;

    return unless $self->id;

    $message .= AberMUD::Util::colorify($self->prompt) unless $args{no_prompt};

    $self->universe->_controller->send($self->id => $message);
}

sub sendf {
    my $self    = shift;
    my $message = shift;

    $self->send(sprintf($message, @_));
}

__PACKAGE__->meta->make_immutable;

1;
