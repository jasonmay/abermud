#!/usr/bin/env perl
package AberMUD::Object::Role::Closeable;
use Moose::Role;
use namespace::autoclean;

has close_description => (
    is  => 'rw',
    isa => 'Str',
);

has closed => (
    is  => 'rw',
    isa => 'Str',
);


1;

