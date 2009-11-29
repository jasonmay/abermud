#!/usr/bin/env perl
package AberMUD::Object::Role::Getable;
use Moose::Role;

has weight => (
    is => 'rw',
    isa => 'Int',
);

has size => (
    is => 'rw',
    isa => 'Int',
);

no Moose::Role;

1;

