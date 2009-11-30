#!/usr/bin/env perl
package AberMUD::Object::Role::Pushable;
use Moose::Role;

has pushed_description => (
    is  => 'rw',
    isa => 'Str',
);

has pushed => (
    is  => 'rw',
    isa => 'Bool',
);

no Moose::Role;

1;

