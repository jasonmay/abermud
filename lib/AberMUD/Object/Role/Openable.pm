#!/usr/bin/env perl
package AberMUD::Object::Role::Openable;
use Moose::Role;
use namespace::autoclean;

has open_description => (
    is  => 'rw',
    isa => 'Str',
);

has open_text => (
    is  => 'rw',
    isa => 'Str',
);

has opened => (
    is  => 'rw',
    isa => 'Str',
);

override openable => sub { 1 };

1;

