#!/usr/bin/env perl
package AberMUD::Object::Role::Closeable;
use Moose::Role excludes => qw(AberMUD::Object::Role::Openable);

has close_description => (
    is  => 'rw',
    isa => 'Str',
);

has closed => (
    is  => 'rw',
    isa => 'Str',
);

no Moose::Role;

1;

