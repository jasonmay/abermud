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

sub open {
    my $self = shift;

    $self->_opened(1);
}

sub _opened {
    my $self = shift;
    my $open = shift;
    my $only_this_object = shift;

    $self->opened($open);

    if ($self->gateway and !$only_this_object) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $self->$link_method;
            next unless $self->$link_method->openable;
            $self->$link_method->_opened($open, 1);
        }
    }

    if ($self->gateway) {
        if ($open) {
            $self->universe->revealing_gateway_cache->insert($self)
        }
        else {
            $self->universe->revealing_gateway_cache->remove($self)
        }
    }
}

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

