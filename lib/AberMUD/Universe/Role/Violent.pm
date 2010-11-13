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

    foreach my $mobile ($self->get_mobiles) {
        $mobile->attack if $mobile->fighting;
    }

    foreach my $player ($self->game_list) {
        $player->attack if $player->fighting;
    }
}

1;

