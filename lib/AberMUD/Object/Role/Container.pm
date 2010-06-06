#!/usr/bin/env perl
package AberMUD::Object::Role::Container;
use Moose::Role;
use namespace::autoclean;

sub containing {
    my $self = shift;

    #TODO return list of objects inside this object
}

1;

