#!/usr/bin/env perl
package AberMUD::Universe::Role::Violent;
use Moose::Role;
use namespace::autoclean;

requires qw(players);

around advance => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        unless $self->does('AberMUD::Universe::Role::Mobile');

    for my $mobile ($self->get_mobiles) {
        next unless $mobile->can('start_fight');
        next unless $mobile->aggression;
        next if $mobile->fighting;

        if ($self->roll_to_start_fight($mobile)) {
            $mobile->start_fight;
        }
    }

    $self->fight_iteration();

    return $self->$orig(@_);
};

sub roll_to_start_fight {
    my $self = shift;
    my ($mob) = @_;

    my $roll = rand 100;
    my $go = !!($mob->aggression >= $roll);

    return $go;
}

sub fight_iteration {
    my $self = shift;
    my $type = shift || '';

    #foreach my $mobile ($self->get_mobiles) {
    #    if ($mobile->fighting) {
    #        $mobile->fighting->fighting($mobile)
    #            if $mobile->fighting->fighting != $mobile;
    #        $mobile->attack;
    #    }
    #}

    foreach my $player ($self->game_list) {
        if ($player->fighting) {
            if ($player->location != $player->fighting->location) {
                $player->append_output_buffer("I guess you're not fighting anymore..\n");
                $player->stop_fighting;
                next;
            }
            $player->fighting->fighting($player)
                if $player->fighting->fighting != $player;
            $player->attack(universe => $self);
            if ($player->fighting) { #could have killed
                $player->fighting->attack(universe => $self);
            }
        }
    }
}

1;

