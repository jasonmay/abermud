#!/usr/bin/env perl
package AberMUD::Input::Command::Wear;
use AberMUD::OO::Commands;

command wear => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args
        or return "What do you want to wear?";

    my $object = $you->universe->identify_object($you->location, $args[0])
        or return "Nothing like that was found.";

    $object->getable and $object->wearable or return "You can't wear that!";

    $object->held_by &&
        $object->held_by == $you or return "You aren't carrying that.";

    $object->worn and return "You're already wearing that!";

    my %coverage = $you->coverage;

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
