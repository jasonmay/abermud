#!/usr/bin/env perl
package AberMUD::Input::State;
use Moose;
extends 'MUD::Input::State';

has 'entry_message' => (
    is => 'rw',
    isa => 'Str',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

