#!/usr/bin/env perl
package AberMUD::Object::Role::Openable;
use Moose::Role;
use namespace::autoclean;

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
);

sub open {
    my $self = shift;

    $self->opened(1);
    $self->universe->revealing_gateway_cache->insert($self)
        if $self->gateway;
}

sub openable { 1 }

1;

