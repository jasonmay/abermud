#!/usr/bin/env perl
package AberMUD::Input::State;
use Moose;
use namespace::autoclean;
extends 'MUD::Input::State';

has 'entry_message' => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;

