#!/usr/bin/env perl
package AberMUD::Object::Role::Pushable;
use Moose::Role;

has pushed_description => (
    is  => 'rw',
    isa => 'Str',
);

no Moose::Role;

1;

