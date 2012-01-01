#!/usr/bin/env perl
package AberMUD::Input::Command::Open;
use AberMUD::OO::Commands;
use AberMUD::Location::Util qw(directions);

command open => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments
        or return "What do you want to open?";

    my $object = $e->universe->identify_object($e->player->location, $args[0])
        or return "Nothing like that was found.";

    $object->openable or return "You can't open that.";

    $object->opened and return "That's already open.";

    my $key;
    if ($object->lockable and $object->locked) {
        # TODO check if user is carrying a key
        $key = $e->player->carrying_key
            or return "You can't open that. It's locked.";

        $object->locked(0);
    }

    $e->universe->open($object);

    return sprintf(
        'You use your %s to unlock and open the %s',
        $key->formatted_name,
        $object->formatted_name,
    ) if $key;

    return "You open the " . $object->formatted_name;
};

__PACKAGE__->meta->make_immutable;

1;
