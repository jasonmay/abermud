#!/usr/bin/env perl
package AberMUD::Object::Role::Pushable;
use Moose::Role;
use namespace::autoclean;

has pushed_description => (
    is  => 'rw',
    isa => 'Str',
);

has push_text => (
    is  => 'rw',
    isa => 'Str',
);

has pushed => (
    is  => 'rw',
    isa => 'Bool',
);

sub pushable { 1 }

around final_description => sub {
    my ($orig, $self) = @_;

    return $self->pushed_description if $self->pushed_description;

    return $self->$orig(@_);
};

1;

