#!/usr/bin/env perl
package AberMUD::Input::Command::Examine;
use AberMUD::OO::Commands;

command examine => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (!@args) {
        return "Examine what?";
    }
    else {
        my $in_game = $universe->identify($you->location, $args[0])
            or return "Nothing of that name is here.";

        return $in_game->examine_description
            || "You notice nothing special.";
    }
};

__PACKAGE__->meta->make_immutable;

1;
