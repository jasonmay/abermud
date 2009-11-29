#!/usr/bin/env perl
package AberMUD::Object::Role::Booze;
use Moose::Role;

with qw(
    AberMUD::Object::Role::Food
);

no Moose::Role;

1;

