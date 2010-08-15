#!/usr/bin/env perl
package AberMUD::Object::Role::Pushable;
use Moose::Role;
use namespace::autoclean;

has pushed_description => (
    is  => 'rw',
    isa => 'Str',
);

has push_text => (
    is  => 'rw',
    isa => 'Str',
);

has pushed => (
    is  => 'rw',
    isa => 'Bool',
);


1;

