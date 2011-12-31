#!/usr/bin/env perl
package AberMUD::Input::Command::Put;
use AberMUD::OO::Commands;

command put => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (@args == 3 and lc($args[1]) eq 'in') {
        my $object    = $universe->identify_object($you->location, $args[0])
            or return "I don't know what that is.";

        my $container = $universe->identify_object($you->location, $args[2])
            or return "I don't know what that is.";

        $container->container or return "That's not a container!";

        $container->getable and $container->contained_by
            and return "You need to take the " .
                $container->name . " out of the " .
                $container->contained_by->name . " first.";

        $object->getable or return "You can't take that!";

        if ($object->held_by and $object->held_by != $you) {
            return "That's not yours!";
        }

        $object->contained_by and return "That's already inside something.";

        return "That would be quite the topological feat." if $object == $container;

        $object->_stop_being_held() if $object->held_by;

        $object->contained_by($container);

        return sprintf(
            'You put the %s in the %s.',
            $object->name, $container->name,
        );
    }
    else {
        return "Put what in what?";
    }
};

__PACKAGE__->meta->make_immutable;

1;
