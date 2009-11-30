#!/usr/bin/env perl
package AberMUD::Object::Role::Openable;
#use Moose::Role -excludes => qw(AberMUD::Object::Role::Closeable);
use Moose::Role;

has open_description => (
    is  => 'rw',
    isa => 'Str',
);

has opened => (
    is  => 'rw',
    isa => 'Str',
);

no Moose::Role;

1;

