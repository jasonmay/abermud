#!/usr/bin/env perl
package AberMUD::Object::Role::Wearable;
use Moose::Role;
use namespace::autoclean;

has armor => (
    is => 'rw',
    isa => 'Int',
);


1;

