#!/usr/bin/env perl
package AberMUD::Input::Command;
use Moose;
use namespace::autoclean;
use Carp;

has name => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_build_name',
);

sub _build_name {
    croak "Please override the '_build_name' method.";
}

has alias => (
    is  => 'rw',
    isa => 'Str',
);

sub run {
    croak "Please override the 'run' method.";
}

__PACKAGE__->meta->make_immutable;

1;

