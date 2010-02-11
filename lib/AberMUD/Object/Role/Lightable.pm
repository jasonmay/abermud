#!/usr/bin/env perl
package AberMUD::Object::Role::Lightable;
use Moose::Role;
use namespace::autoclean;

has lit => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);


1;

