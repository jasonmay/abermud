#!/usr/bin/env perl
package AberMUD::Mobile::Role::Hostile;
use Moose::Role;
use namespace::autoclean;
use Try::Tiny;

has aggression => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

1;

