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
    AberMUD::Role::Humanoid
);

has '+location' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

has prompt => (
    is      => 'rw',
    isa     => 'Str',
    default => '>',
);

has storage => (
    is       => 'rw',
    isa      => 'AberMUD::Storage',
    required => 1,
    weak_ref => 1,
    traits   => ['KiokuDB::DoNotSerialize'],
);

has password => (
    is  => 'rw',
    isa => 'Str',
);

has markings => (
    is  => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
    traits => ['Hash'],
    handles => {
        'mark' => 'set',
    }
);

sub id {
    my $self = shift;

    my $p = $self->universe->players;
    return first_value { $p->{$_} == $self } keys %$p;
}

has dir_player => (
    is     => 'rw',
    isa    => 'AberMUD::Player',
    traits => ['KiokuDB::DoNotSerialize'],
);

has '+input_state' => (
    isa    => 'ArrayRef[AberMUD::Input::State]',
    traits => ['KiokuDB::DoNotSerialize'],
);

has special_composite => (
    is       => 'rw',
    isa      => 'AberMUD::Special',
    traits   => ['KiokuDB::DoNotSerialize'],
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
