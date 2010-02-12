#!/usr/bin/env perl
package AberMUD::Object::Role::Container;
use Moose::Role;
use namespace::autoclean;

has contained_by => (
    is  => 'rw',
    isa => 'AberMUD::Object',
);

sub containing {
    my $self = shift;

    #TODO return list of objects inside this object
}

1;

