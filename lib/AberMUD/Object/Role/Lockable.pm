#!/usr/bin/env perl
package AberMUD::Object::Role::Lockable;
use Moose::Role;

has lock_description => (
    is  => 'rw',
    isa => 'Str',
);

has lock_action => (
    is  => 'rw',
    isa => 'Str',
);

no Moose::Role;

1;

