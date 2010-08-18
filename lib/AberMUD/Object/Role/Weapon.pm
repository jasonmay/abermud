#!/usr/bin/env perl
package AberMUD::Object::Role::Weapon;
use Moose::Role;
use namespace::autoclean;

has wielded => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

override wieldable => sub { 1 };

around on_the_ground => sub {
    my ($orig, $self) = @_;

    return 0 if $self->wielded;

    $self->$orig(@_);
};

1;
