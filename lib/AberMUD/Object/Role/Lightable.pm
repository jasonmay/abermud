#!/usr/bin/env perl
package AberMUD::Object::Role::Lightable;
use Moose::Role;

has lit => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

no Moose::Role;

1;

