#!/usr/bin/env perl
package AberMUD::Input::Command::Examine;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args;

    if (!@args) {
        return "Take what?";
    }
    else {
        my @matching_objects = grep {
            $_->location == $you->location
            and lc($_->name) eq lc($args[0])
        } $you->universe->objects;

        if (@matching_objects) {
            my $o = $matching_objects[0];
            return $o->examine_description
                || "You don't notice anything special."
        }

        return "No object of that name is here.";
    }
}

__PACKAGE__->meta->make_immutable;

1;
