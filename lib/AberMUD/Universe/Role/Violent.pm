#!/usr/bin/env perl
package AberMUD::Universe::Role::Violent;
use Moose::Role;
use namespace::autoclean;

around advance => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        unless $self->does('AberMUD::Universe::Role::Mobile');

    for my $mobile ($self->get_mobiles) {
        next unless $mobile->does('AberMUD::Mobile::Role::Hostile');

        if ($self->roll_to_start_fight($mobile)) {
            $self->start_fight($mobile);
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

    foreach my $player ($self->player_list) {
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

sub start_fight {
    my $self   = shift;
    my $mobile = shift;

    return unless $mobile->can('fighting');
    return unless $mobile->location;

    my @potential_victims = grep {
        $_ != $mobile and
        $_->location and
        $_->location == $mobile->location
    } $self->player_list;

    return unless @potential_victims;
    my $killable = $potential_victims[rand @potential_victims];
    $mobile->start_fighting($killable);
}

1;

