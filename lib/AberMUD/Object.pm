#!/usr/bin/env perl
package AberMUD::Object;
use Moose;
use namespace::autoclean;

with qw(AberMUD::Role::InGame);

has name => (
    is => 'rw',
    isa => 'Str',
);

has buy_value => (
    is => 'rw',
    isa => 'Int',
);

has description => (
    is => 'rw',
    isa => 'Str',
);

has examine_description => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;
