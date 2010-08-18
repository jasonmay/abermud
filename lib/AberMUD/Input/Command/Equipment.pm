#!/usr/bin/env perl
package AberMUD::Input::Command::Equipment;
use AberMUD::OO::Commands;
use List::Util qw(first);

command equipment => sub {
    my $you  = shift;
    my $args = shift;

    my $output = 'On Hand:             ';

    my $weapon = first {
        $_->wieldable and $_->getable
            and $_->wielded
            and $_->held_by == $you
    } $you->universe->objects;

    if ($weapon) {
        $output .= $weapon->name;
    }
    else {
        $output = 'Unarmed';
    }

    $output .= "\n=============================\n";

    my $bare = 1;
    foreach my $armor ($you->universe->objects) {
        next unless $armor->getable;
        next unless $armor->wearable;
        next unless $armor->worn;
        next unless $armor->held_by == $you;

        foreach my $part (keys %{$armor->coverage || {}}) {
            $output .= $part . ': ' . $armor->name . "\n";
        }
        $bare = 0;
    }

    $output .= "=============================\n";

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
