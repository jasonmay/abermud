#!/usr/bin/env perl
package AberMUD::Input::Command::Close;
use AberMUD::OO::Commands;

command close => sub {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args
        or return "What do you want to close?";

    my $object = $you->universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->closeable or return "You can't close that.";

    $object->closed and return "That's already closed.";

    $object->closed(1);

    return "You open the " . $object->name;
};

__PACKAGE__->meta->make_immutable;

1;
