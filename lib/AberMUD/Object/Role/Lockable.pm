#!/usr/bin/env perl
package AberMUD::Object::Role::Lockable;
use Moose::Role;
use namespace::autoclean;

has lock_description => (
    is  => 'rw',
    isa => 'Str',
);

has lock_text => (
    is  => 'rw',
    isa => 'Str',
);

override lockable => sub { 1 };

1;

