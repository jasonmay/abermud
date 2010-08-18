#!/usr/bin/env perl
package AberMUD::Input::Command::Wear;
use AberMUD::OO::Commands;

command wear => sub {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args
        or return "What do you want to wear?";

    my $object = $you->universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->getable and $object->wearable or return "You can't wear that!";

    $object->held_by &&
        $object->held_by == $you or return "You aren't carrying that.";

    $object->worn and return "You're already wearing that!";

    # FIXME can't overlap body parts
    $object->worn(1);

    return "You put on the " . $object->name . ".";
};

__PACKAGE__->meta->make_immutable;

1;
