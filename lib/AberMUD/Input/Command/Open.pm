#!/usr/bin/env perl
package AberMUD::Input::Command::Open;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

command open => sub {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args
        or return "What do you want to open?";

    my $object = $you->universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->openable or return "You can't open that.";

    $object->opened and return "That's already open.";

    my $key;
    if ($object->lockable and $object->locked) {
        # TODO check if user is carrying a key
        $key = $you->carrying_key
            or return "You can't open that. It's locked.";

        $object->locked(0);
    }

    $object->open();

    return sprintf(
        'You use your %s to unlock and open the %s',
        $key->formatted_name,
        $object->formatted_name,
    ) if $key;

    return "You open the " . $object->formatted_name;
};

__PACKAGE__->meta->make_immutable;

1;
