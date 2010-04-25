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
    my @killables_in_room = grep {
        $_ != $self and
        $_->location and
        $_->location == $self->location
    } $self->universe->game_list;

    return unless @killables_in_room;
    my $killable = $killables_in_room[rand @killables_in_room];
    try {
        $self->fighing($killable);
    }
    catch {
        require Data::Dumper;
        warn Data::Dumper::Dumper(map { $_->name } @killables_in_room);
    }
}

1;

