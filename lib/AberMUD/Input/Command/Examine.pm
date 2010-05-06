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
        return "Examine what?";
    }
    else {
        my $in_game = $you->universe->identify($you->location, $args[0])
            or return "Nothing of that name is here.";

        return $in_game->examine_description
            || "You notice nothing special.";
    }
}

__PACKAGE__->meta->make_immutable;

1;
