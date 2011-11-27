#!/usr/bin/env perl
package AberMUD::Object::Role::Closeable;
use Moose::Role;
use namespace::autoclean;

has closed_description => (
    is  => 'rw',
    isa => 'Str',
);

sub closed {
    my $self = shift;
    my $arg = shift;

    if ($arg) {
        return $self->_opened(!$arg);
    }

    $self->openable or return 1;

    return !$self->opened;
}

sub closeable { 1 }

1;

