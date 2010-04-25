#!/usr/bin/env perl
package AberMUD::Universe::Sets;
use KiokuDB::Class;
use Set::Object;
use namespace::autoclean;

has all_objects => (
    is  => 'ro',
    isa => 'HashRef[AberMUD::Object]',
    default => sub { +{} },
);

has all_mobiles => (
    is  => 'rw',
    isa => 'HashRef[AberMUD::Mobile]',
    default => sub { +{} },
);

__PACKAGE__->meta->make_immutable;

1;

