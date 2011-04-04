#!/usr/bin/env perl
package AberMUD::Input::Command::Look;
use AberMUD::OO::Commands;

command 'look', priority => -10, sub {
    my $universe = shift;
    my $you      = shift;
    my $args     = shift;

    if (!$args) {
        return "You are somehow nowhere." unless defined $you->location;
        return $universe->look($you->location);
    }

    my @args = split ' ', $args;

    if (lc($args[0]) eq 'in') {
        return "Look in what?" unless $args[1];

        my $object = $you->universe->identify_object(
            $you->location, $args[1]
        ) or return "I don't see anything like that.";

        $object->container or return "You can't look in that!";

        $object->openable and $object->opened or return "It's closed.";

        my $output = $object->display_contents();
    }
    else {
        return "LOL"; # TODO should do same as "examine"
    }
};

__PACKAGE__->meta->make_immutable;

1;
