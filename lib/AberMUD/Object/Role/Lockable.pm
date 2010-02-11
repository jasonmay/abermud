#!/usr/bin/env perl
package AberMUD::Object::Role::Lockable;
use Moose::Role;
use namespace::autoclean;

has lock_description => (
    is  => 'rw',
    isa => 'Str',
);

has lock_action => (
    is  => 'rw',
    isa => 'Str',
);


1;

