#!/usr/bin/env perl
package AberMUD::Input::State;
use Moose::Role;

has universe => (
    is       => 'rw',
    isa      => 'AberMUD::Universe',
);

has entry_message => (
    is => 'rw',
    isa => 'Str',
);

requires 'run';

no Moose::Role;

1;

