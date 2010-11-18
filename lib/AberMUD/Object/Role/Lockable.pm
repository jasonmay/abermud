#!/usr/bin/env perl
package AberMUD::Object::Role::Lockable;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Location::Util qw(directions);

has locked_description => (
    is  => 'rw',
    isa => 'Str',
);

has lock_text => (
    is  => 'rw',
    isa => 'Str',
);

has locked => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub lockable { 1 }

sub lock {
    my $self = shift;
    $self->locked(1);
    $self->_set_gateway_lock(1);
}

sub unlock {
    my $self = shift;

    $self->locked(0);
    $self->_set_gateway_lock(0);
}

sub _set_gateway_lock {
    my $self = shift;
    my $lock = shift;

    if ($self->gateway) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $self->$link_method;
            next unless $self->$link_method->openable;
            #warn sprintf(
            #    '%slocking %s in %s...',
            #    'un' x $lock,
            #    $self->$link_method,
            #    $self->$link_method->final_location->title,
            #);
            $self->$link_method->locked($lock);
        }
    }
}

around final_description => sub {
    my ($orig, $self) = @_;

    return $self->locked_description if $self->locked;

    return $self->$orig(@_);
};

1;

