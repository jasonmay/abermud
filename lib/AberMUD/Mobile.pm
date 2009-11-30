#!/usr/bin/env perl
package AberMUD::Mobile;
use Moose;
use namespace::autoclean;

with qw(
    AberMUD::Role::Killable
    AberMUD::Role::InGame
);

has id => (
    is  => 'rw',
    isa => 'Str',
);

has name => (
    is  => 'rw',
    isa => 'Str',
);

has display_name => (
    is  => 'rw',
    isa => 'Str',
);

has speed => (
    is  => 'rw',
    isa => 'Str',
);

has intrinsics => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

has spells => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

__PACKAGE__->meta->make_immutable;

1;

