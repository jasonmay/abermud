#!/usr/bin/env perl
package AberMUD::Input::Command::Wield;
use AberMUD::OO::Commands;

command wield => sub {
    my ($self, $e) = @_;

    my @args = split ' ', $e->arguments
        or return "What do you want to wield?";

    my $object = $e->universe->identify_object($e->player->location, $args[0])
        or return "Nothing like that was found.";

    $object->wieldable or return "That's not a weapon!";

    $object->getable or return "You can't wield that!";

    $object->held_by &&
        $object->held_by == $e->player or return "You aren't carrying that.";

    $object->wielded and return "You're already wielding that!";

    foreach my $wielded ($e->universe->get_objects) {
        next unless $wielded->wieldable;
        next unless $wielded->getable;
        next unless $wielded->held_by;
        next unless $wielded->held_by == $e->player;

        if ($wielded->wielded) {
            $wielded->wielded(0);
            $e->player->_stop_wielding;
        }
    }

    $object->wielded(1);
    $e->player->wielding($object);

    return "You wield the " . $object->name . ".";
};

__PACKAGE__->meta->make_immutable;

1;
