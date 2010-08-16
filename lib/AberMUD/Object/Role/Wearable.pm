#!/usr/bin/env perl
package AberMUD::Object::Role::Wearable;
use Moose::Role;
use namespace::autoclean;

has armor => (
    is => 'rw',
    isa => 'Int',
);

has coverage => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
);

has worn => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

around on_the_ground => sub {
    my ($orig, $self) = @_;

    return 0 if $self->worn;

    $self->$orig(@_);
};

1;

