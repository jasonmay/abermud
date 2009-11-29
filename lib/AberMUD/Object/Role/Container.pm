#!/usr/bin/env perl
package AberMUD::Object::Role::Container;
use Moose::Role;

sub containing {
    my $self = shift;

    #TODO return list of objects inside this object
}

no Moose::Role;

1;

