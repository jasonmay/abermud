#!/usr/bin/env perl
package AberMUD::Input::Command::Equipment;
use AberMUD::OO::Commands;
use List::Util qw(first);
use AberMUD::Object::Util qw(bodyparts);

command equipment => sub {
    my $you  = shift;
    my $args = shift;


    my $weapon = first {
        $_->wieldable and $_->getable
            and $_->wielded
            and $_->held_by == $you
    } $you->universe->get_objects;

    my $output = sprintf('%-20s', '&+CWielding:&*');

    if ($weapon) {
        $output .= $weapon->name;
    }
    else {
        $output = 'Unarmed';
    }

    $output .= "\n&+C=============================\n";

    my $bare = 1;

    my %coverage = $you->coverage;

    foreach my $part (bodyparts()) {
        next unless $coverage{$part};
        $output .= sprintf('%-20s', '&+C'.ucfirst($part).':&*');

        if ($coverage{$part}) {
            $output .= $coverage{$part}->name;
        }
        $output .= "\n";
    }

    $output .= "&+C=============================\n";

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
