#!/usr/bin/env perl
package AberMUD::Object::Role::Closeable;
use Moose::Role;

has close_description => (
    is  => 'rw',
    isa => 'Str',
);

no Moose::Role;

1;

