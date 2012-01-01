#!/usr/bin/env perl
package AberMUD::Input::Command::Examine;
use AberMUD::OO::Commands;

command examine => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments;

    if (!@args) {
        return "Examine what?";
    }
    else {
        my $in_game = $e->universe->identify($e->player->location, $args[0])
            or return "Nothing of that name is here.";

        return $in_game->examine_description
            || "You notice nothing special.";
    }
};

__PACKAGE__->meta->make_immutable;

1;
