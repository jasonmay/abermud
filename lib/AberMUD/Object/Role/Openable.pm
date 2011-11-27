#!/usr/bin/env perl
package AberMUD::Object::Role::Openable;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Location::Util qw(directions);

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
    isa => 'Bool',
    default => 0,
);

around final_description => sub {
    my ($orig, $self) = @_;

    if ($self->opened and $self->open_description) {
        return $self->open_description;
    }
    elsif (defined($self->opened) and $self->closed_description) {
        return $self->closed_description;
    }

    return $self->$orig(@_);
};

sub openable { 1 }

1;

