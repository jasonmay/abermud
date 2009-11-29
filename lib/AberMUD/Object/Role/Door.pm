#!/usr/bin/env perl
package AberMUD::Object::Role::Door;
use Moose::Role;
use Moose::Util::TypeConstraints;

with qw(
    AberMUD::Object::Role::Openable
    AberMUD::Object::Role::Closeable
);

has opening_link => (
    is  => 'rw',
    isa => subtype('Moose::Object' => where {
        !$_ || $_->does('AberMUD::Object::Role::IsDoor')
    })
);

no Moose::Role;

1;

