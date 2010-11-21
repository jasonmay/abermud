#!/usr/bin/env perl
package AberMUD::Player;
use KiokuDB::Class;
use namespace::autoclean;
extends 'MUD::Player';

use AberMUD::Location;
use AberMUD::Location::Util qw(directions show_exits);

use Carp qw(cluck);
use List::Util qw(first);
use List::MoreUtils qw(first_value);

=head1 NAME

AberMUD::Player - AberMUD Player class for playing

=head1 SYNOPSIS

    my $player = AberMUD::Player->new;

=head1 DESCRIPTION

XXX

=cut

with qw(
    MooseX::Traits
    AberMUD::Player::Role::InGame
    AberMUD::Role::Killable
);

has '+location' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

has prompt => (
    is  => 'rw',
    isa => 'Str',
    default => '>',
);

has storage => (
    is        => 'rw',
    isa       => 'AberMUD::Storage',
    required  => 1,
    weak_ref  => 1,
    traits => ['KiokuDB::DoNotSerialize'],
);

has password => (
    is => 'rw',
    isa => 'Str',
);

has '+universe' => (
    handles => {get_global_input_state => '_get_input_state'},
);

sub id {
    my $self = shift;

    my $p = $self->universe->players;
    return first_value { $p->{$_} == $self } keys %$p;
}

has dir_player => (
    is        => 'rw',
    isa       => 'AberMUD::Player',
    traits => ['KiokuDB::DoNotSerialize'],
);

has '+input_state' => (
    isa    => 'ArrayRef[AberMUD::Input::State]',
    traits => ['KiokuDB::DoNotSerialize'],
);

has special_composite => (
    is => 'rw',
    isa => 'AberMUD::Special',
    traits => ['KiokuDB::DoNotSerialize'],
    required => 1,
);

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
    return $self->universe->storage->lookup('player-' . lc $self->name);
}

sub save_data {
    my $self = shift;
    my %args = @_;

    my $u    = $self->universe;

    if (!$self->in_game) {
        #cluck "Trying to call save when the player is not in-game";
        return;
    }

    if ($self->storage->player_lookup($self->name)) {
        $u->storage->update($self);
    }
    else {
        $u->storage->store('player-' . lc $self->name => $self);
    }
}

sub load_data {
    my $self = shift;
    my $u    = $self->universe;

    if ($self->is_saved) {
        my $player
            = $u->storage->lookup('player-' . lc $self->name);
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

    if ($self->dead) {

        my $restore = int($self->max_strength * 2 / 3);
        $restore = 40 if $restore < 40;

        # restore strength
        $self->current_strength($restore);
        $self->dead(0);
        $self->save_data();
    }
}

sub _ghost {
    my $self   = shift;
    my $victim = shift;
    my $u = $self->universe;

    return unless $victim->id and $self->id;

    $u->_controller->force_disconnect($victim->id, ghost => 1);
    $u->players->{$self->id} = delete $u->players->{$victim->id};
}

sub materialize {
    my $self = shift;
    my $u    = $self->universe;

    return $self if $self->in_game;

    $self->sys_message("materialize");

    my $m_player = $self->dir_player || $self;

    if ($m_player != $self && $m_player->in_game) {
        $self->_ghost($m_player);
        return $self;
    }

    if (!$m_player->in_game) {
        $m_player->_copy_unserializable_data($self);
        $m_player->_join_server($self->id);
    }

    $m_player->_join_game;
    $m_player->save_data if $m_player == $self;
    $m_player->setup;

    return $m_player;
}

sub dematerialize {
    my $self = shift;
    delete $self->universe->players_in_game->{lc $self->name};
}

sub look {
    my $self   = shift;
    my $loc    = shift || $self->location;

    my $output = sprintf(
        "&+M%s&* &+B[&+C%s@%s&+B]&*\n",
        $loc->title,
        lc substr($self->universe->storage->object_to_id($loc), 0, 8),
        $loc->zone->name,
    );

    $output .= $loc->description;
    chomp $output; $output .= "\n";

    foreach my $object ($self->universe->get_objects) {
        next unless $object->location;
        next unless $object->location == $loc;
        next unless $object->on_the_ground;

        my $desc = $object->final_description;
        next unless $desc;

        $output .= "$desc\n";
    }

    foreach my $mobile ($self->universe->get_mobiles) {
        next unless $mobile->location;
        my $desc = $mobile->description;
        $desc .= sprintf q( [%s/%s]), $mobile->current_strength, $mobile->max_strength;
        $desc .= sprintf q( [agg: %s]), $mobile->aggression;

        if ($mobile->location == $self->location) {
            $output .= "$desc\n";
            my $inv = $mobile->show_inventory;
            $output .= "$inv\n" if $inv;
        }
    }

    foreach my $player (values %{$self->universe->players_in_game}) {
        next if $player == $self;
        $output .= ucfirst($player->name) . " is standing here.\n"
            if $player->location == $self->location;
    }

    $output .= "\n" . show_exits(location => $loc, universe => $self->universe);

    return $output;
}

sub send {
    my $self    = shift;
    my $message = shift;
    my %args    = @_;

    return unless $self->id;

    $message .= AberMUD::Util::colorify($self->final_prompt) unless $args{no_prompt};

    $self->universe->_controller->send($self->id => AberMUD::Util::colorify($message));
}

sub sendf {
    my $self    = shift;
    my $message = shift;

    $self->send(sprintf($message, @_));
}

sub final_prompt {
    my $self = shift;
    my $prompt = $self->prompt;

    $prompt =~ s/%h/$self->current_strength/e if $self->can('current_strength');
    $prompt =~ s/%H/$self->max_strength/e     if $self->can('max_strength');

    #$prompt =~ s/%m/$self->current_mana/e;
    #$prompt =~ s/%M/$self->max_mana/e;

    return $prompt;
}

sub death {
    my $self = shift;

    $self->save_data();
    $self->dematerialize();

    $self->send(<<DEATH, no_prompt => 1);

&+r***********************************&N
      I guess you died! LOL!
&+r***********************************&N
DEATH

    $self->disconnect;
};

sub change_score {
    my $self = shift;
    my $delta = shift;

    my $prev_level = $self->level;

    $self->score($self->score + $delta);

    if ($self->level > $prev_level) {

        if ($self->level > $self->max_level) {
            for ($prev_level + 1 .. $self->level) {
                $self->universe->broadcast(
                    sprintf(
                        "Congratulations to %s for making it to level &+C$_&*.\n",
                        $self->name
                    ),
                    except => $self,
                );

                $self->send("Congratulations! You made it to level &+C$_&*.\n"),
            }
            $self->max_level($self->level);
        }
    }
    elsif ($self->level < $prev_level) {
            $self->sendf(
                "You are back to level &+C%s&*.\n",
                $self->level,
            );
    }

    $self->save_data();
}

__PACKAGE__->meta->make_immutable;

1;
