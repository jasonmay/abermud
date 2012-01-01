#!/usr/bin/env perl
package AberMUD::Input::Command::Wear;
use AberMUD::OO::Commands;

command wear => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments
        or return "What do you want to wear?";

    my $object = $e->universe->identify_object($e->player->location, $args[0])
        or return "Nothing like that was found.";

    $object->getable and $object->wearable or return "You can't wear that!";

    $e->player->_carrying->has($object) or return "You aren't carrying that.";

    $object->worn and return "You're already wearing that!";

    my %coverage = $e->player->coverage;

    if ($object->coverage) {
        foreach my $part (keys %{ $object->coverage }) {
            next unless $object->coverage->{$part};

            if ($coverage{$part}) {
                return "Please remove your " .
                    $coverage{$part}->name . " first.";
            }
        }
    }

    $object->worn(1);

    return "You put on the " . $object->name . ".";
};

__PACKAGE__->meta->make_immutable;

1;
