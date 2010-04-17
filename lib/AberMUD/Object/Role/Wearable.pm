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

1;

