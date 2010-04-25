#!/usr/bin/env perl
package AberMUD::Universe::Role::Violent;
use Moose::Role;
use namespace::autoclean;

requires qw(players);

around advance => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_) unless $self->does('AberMUD::Universe::Role::Mobile');
    for my $mobile ($self->mobiles) {
        next unless $mobile->can('start_fight');
        if ($self->roll_to_start_fight) {
            warn sprintf( "fight %s fight!", $mobile->name);
            $mobile->start_fight;
        }
    }
    return $self->$orig(@_);
};

sub roll_to_start_fight {
    my $self = shift;

    my $go = !!(10 >= rand 100);
    # 1 to 10 odds
    return $go;
}


1;

