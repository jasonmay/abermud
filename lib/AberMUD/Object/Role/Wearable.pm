#!/usr/bin/env perl
package AberMUD::Object::Role::Wearable;
use Moose::Role;

has armor => (
    is => 'rw',
    isa => 'Int',
);

no Moose::Role;

1;

