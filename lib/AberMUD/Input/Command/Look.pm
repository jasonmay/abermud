#!/usr/bin/env perl
package AberMUD::Input::Command::Look;
use AberMUD::OO::Commands;

command 'look', priority => -10, sub {
    my ($self, $e) = @_;

    if (!$e->arguments) {
        return "You are somehow nowhere." unless defined $e->player->location;
        return $e->universe->look($e->player->location, except => $e->player);
    }

    my @args = split ' ', $e->arguments;

    if (lc($args[0]) eq 'in') {
        return "Look in what?" unless $args[1];

        my $object = $e->universe->identify_object(
            $e->player->location, $args[1]
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
