#!/usr/bin/env perl
package AberMUD::Input::State;
use Moose;

sub run { die "This method must be overwritten" }

has universe => (
    is       => 'rw',
    isa      => 'AberMUD::Universe',
);

has entry_message => (
    is => 'rw',
    isa => 'Str',
);

no Moose;

1;

