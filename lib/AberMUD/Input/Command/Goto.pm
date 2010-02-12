#!/usr/bin/env perl
package AberMUD::Input::Command::Goto;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    my $args = shift;

    (my $loc_id = lc $args) =~ s/\W//g;

    my $loc = $you->universe->directory->lookup("location-$loc_id");

    if (!$loc) {
        return "Could not find that location.";
    }

    $you->location($loc);
    return $you->look;
}



__PACKAGE__->meta->make_immutable;

1;

