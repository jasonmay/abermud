#!/usr/bin/env perl
package AberMUD::Object::Role::Door;
use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

with qw(
    AberMUD::Object::Role::Openable
);

has opening_link => (
    is  => 'rw',
    isa => subtype('Moose::Object' => where {
        !$_ || $_->does('AberMUD::Object::Role::Door')
    })
);


1;

