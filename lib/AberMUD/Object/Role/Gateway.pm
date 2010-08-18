#!/usr/bin/env perl
package AberMUD::Object::Role::Gateway;
use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use AberMUD::Location::Util qw(directions);

=head1 NAME

AberMUD::Object::Role::Gateway - object gateway role

=head1 DESCRIPTION

This role is for objects that are a gateway for other objects.
It is mostly for objects that intend to hide and/or revealexits,
such as a door in a room, a boulder in a cave, etc.

=cut

has "${_}_link" => (
    is  => 'rw',
    isa => 'AberMUD::Object',
) for directions();

override gateway => sub { 1 };

1;
