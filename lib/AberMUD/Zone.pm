#!/usr/bin/env perl
package AberMUD::Zone;
use Moose;
use namespace::autoclean;

has name => (
    is => 'rw',
    isa => 'Str',
);

has altitude => (
    is => 'rw',
    isa => 'Int',
);

has rainfall => (
    is => 'rw',
    isa => 'Int',
);

__PACKAGE__->meta->make_immutable;

1;

