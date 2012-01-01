#!/usr/bin/env perl
package AberMUD::Input::Command::Remove;
use AberMUD::OO::Commands;

command remove => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments
        or return "What do you want to take off?";

    my $object = $e->universe->identify_object($e->player->location, $args[0])
        or return "Nothing like that was found.";

    $object->getable and $object->wearable or return "You can't even wear that!";

    $object->held_by &&
        $object->held_by == $e->player or return "You aren't carrying that.";

    $object->worn or return "You're not wearing that!";

    $object->worn(0);

    return "You take off the " . $object->name . ".";
};

__PACKAGE__->meta->make_immutable;

1;
