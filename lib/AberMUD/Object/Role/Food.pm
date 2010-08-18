#!/usr/bin/env perl
package AberMUD::Object::Role::Food;
use Moose::Role;
use namespace::autoclean;

has eaten => (
    is  => 'rw',
    isa => 'Bool',
);

override edible => sub { 1 };

1;

