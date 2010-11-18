#!/usr/bin/env perl
package AberMUD::Object::Role::Key;
use Moose::Role;
use namespace::autoclean;

has to_object => (
    is   => 'ro',
    does => 'AberMUD::Object::Role::Lockable',
);

sub key { 1 }

1;

