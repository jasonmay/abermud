#!/usr/bin/env perl
package AberMUD::Mobile;
use Moose;
use namespace::autoclean;

extends 'AberMUD::Killable';

use AberMUD::Location::Util qw(directions);

with qw(
    AberMUD::Role::InGame
    AberMUD::Role::Humanoid
    AberMUD::Mobile::Role::Hostile
);

has id => (
    is  => 'rw',
    isa => 'Str',
);

has display_name => (
    is  => 'rw',
    isa => 'Str',
);

has speed => (
    is  => 'rw',
    isa => 'Num',
);

has intrinsics => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

has spells => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

has _held_objects => (
    is  => 'ro',
    isa => 'Kioku::Set',
);

sub move {
    my $self = shift;
    return unless $self->location;

    return $self if $self->can('fighting') and $self->fighting;

    my $loc  = $self->location;

    return $self;
}

around name_matches => sub {
    my ($orig, $self) = (shift, shift);
    return 1 if $self->$orig(@_) or (
        $self->display_name
        and lc($self->display_name) eq lc($_[0])
    );

    return 0;
};

sub formatted_name {
    my $self = shift;
    my $result = $self->display_name || $self->name;
    return $result;
}

after death => sub {
    my $self = shift;

    $self->location($self->universe->corpse_location);
};

__PACKAGE__->meta->make_immutable;

1;

