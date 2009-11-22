#!/usr/bin/env perl
package AberMUD::Input::Command;
use Moose;
use namespace::autoclean;
use Carp;

has 'name' => (
    is => 'rw',
    isa => 'Str',
);

has 'alias' => (
    is => 'rw',
    isa => 'Str',
);

sub run {
    croak "You need to override AberMUD::Input::Command::run";
}

__PACKAGE__->meta->make_immutable;

1;

