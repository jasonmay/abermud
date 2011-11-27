#!/usr/bin/env perl
package AberMUD::Input::Command::Close;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

command close => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args
        or return "What do you want to close?";

    my $object = $universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->closeable or return "You can't close that.";

    $object->closed and return "That's already closed.";

    $object->close();

    if ($object->gateway) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $object->$link_method;
            next unless $object->$link_method->closeable;
            $object->$link_method->close();
        }
    }

    return "You close the " . $object->name;
};

__PACKAGE__->meta->make_immutable;

1;
