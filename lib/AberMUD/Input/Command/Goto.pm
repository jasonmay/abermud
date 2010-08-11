#!/usr/bin/env perl
package AberMUD::Input::Command::Goto;
use AberMUD::OO::Commands;

command goto => sub {
    my $you  = shift;
    my $args = shift;

    (my $loc_id = lc $args) =~ s/\W//g;

    my $loc = $you->universe->storage->lookup("location-$loc_id");

    if (!$loc) {
        return "Could not find that location.";
    }

    $you->location($loc);
    return $you->look;
};

__PACKAGE__->meta->make_immutable;

1;

