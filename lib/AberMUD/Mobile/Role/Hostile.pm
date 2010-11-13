#!/usr/bin/env perl
package AberMUD::Mobile::Role::Hostile;
use Moose::Role;
use namespace::autoclean;
use Try::Tiny;

has aggression => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

sub start_fight {
    my $self = shift;
    return unless $self->can('fighting');
    return unless $self->location;

    my @potential_victims = grep {
        $_ != $self and
        $_->location and
        $_->location == $self->location
    } $self->universe->game_list;

    return unless @potential_victims;
    my $killable = $potential_victims[rand @potential_victims];
    $self->fighting($killable);
    $killable->fighting($self);
}

1;

