#!/usr/bin/env perl
package AberMUD::Input::Command::Wield;
use AberMUD::OO::Commands;

command wield => sub {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args
        or return "What do you want to wield?";

    my $object = $you->universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->wieldable or return "That's not a weapon!";

    $object->getable or return "You can't wield that!";

    $object->held_by &&
        $object->held_by == $you or return "You aren't carrying that.";

    $object->wielded and return "You're already wielding that!";

    foreach my $wielded ($you->universe->objects) {
        next unless $wielded->wieldable;
        next unless $wielded->getable;
        next unless $wielded->held_by == $you;

        $wielded->wielded(0) if $wielded->wielded;
    }

    $object->wielded(1);

    return "You wield the " . $object->name . ".";
};

__PACKAGE__->meta->make_immutable;

1;
