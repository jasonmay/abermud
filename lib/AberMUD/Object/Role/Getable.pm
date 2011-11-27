#!/usr/bin/env perl
package AberMUD::Object::Role::Getable;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Player;
use AberMUD::Mobile;

has weight => (
    is  => 'rw',
    isa => 'Int',
);

has size => (
    is  => 'rw',
    isa => 'Int',
);

has held_by => (
    is      => 'rw',
    isa     => 'AberMUD::Player|AberMUD::Mobile',
    clearer => '_stop_being_held',
);

has dropped_description => (
    is  => 'rw',
    isa => 'Str',
);

has dropped => (
    is  => 'rw',
    isa => 'Str',
);

sub getable { 1 }
sub containable { 1 }

around in_direct_possession => sub {
    my ($orig, $self, $killable) = @_;

    my $return = $self->$orig(@_);

    return 1 if $return;

    if ($killable) {
        return $self->held_by
            and $self->held_by == $killable
            and not $self->contained_by;
    }
    else {
        return $self->held_by and not $self->contained_by;
    }
};

around on_the_ground => sub {
    my ($orig, $self) = @_;

    return 0 if $self->held_by;

    return 0 if $self->contained_by;

    $self->$orig(@_);
};

around final_description => sub {
    my ($orig, $self) = @_;

    return $self->dropped_description if $self->dropped_description;

    return $self->$orig(@_);
};

1;

