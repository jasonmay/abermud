#!/usr/bin/env perl
package AberMUD::Input::Command::Close;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

command close => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments
        or return "What do you want to close?";

    my $object = $e->universe->identify_object($e->player->location, $args[0])
        or return "Nothing like that was found.";

    $object->closeable or return "You can't close that.";

    $object->closed and return "That's already closed.";

    $e->universe->close($object);

    if ($object->gateway) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $object->$link_method;
            next unless $object->$link_method->closeable;
            $e->universe->close($object->$link_method);
        }
    }

    return "You close the " . $object->name;
};

__PACKAGE__->meta->make_immutable;

1;
