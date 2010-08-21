#!/usr/bin/env perl
package AberMUD::Object::Role::Container;
use Moose::Role;
use namespace::autoclean;
use KiokuDB::Set qw(weak_set);

override container => sub { 1 };

sub containing {
    my $self   = shift;

    return () unless $self->container;

    return
        grep {
        $_->containable
            && $_->contained_by
            && $_->contained_by == $self
        } $self->universe->get_objects;
}


1;

