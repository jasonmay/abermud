#!/usr/bin/env perl
package AberMUD::Input::Command::Open;
use AberMUD::OO::Commands;

command open => sub {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args
        or return "What do you want to open?";

    my $object = $you->universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->openable or return "You can't open that.";

    $object->opened and return "That's already open.";

    $object->opened(1);

    return "You open the " . $object->name;
};

__PACKAGE__->meta->make_immutable;

1;
