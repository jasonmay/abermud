#!/usr/bin/env perl
package AberMUD::Object::Role::Food;
use Moose::Role;
use namespace::autoclean;

has eaten => (
    is  => 'rw',
    isa => 'Bool',
);

has nutritionn => (
    is  => 'rw',
    isa => 'Int',
    default => 10,
);

sub edible { 1 }

1;

