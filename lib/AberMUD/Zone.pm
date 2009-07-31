#!/usr/bin/env perl
package AberMUD::Zone;
use Moose;

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

no Moose;
__PACKAGE__->meta->make_immutable;

1;

