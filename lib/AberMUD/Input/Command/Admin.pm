#!/usr/bin/env perl
package AberMUD::Input::Command::Admin;
use AberMUD::OO::Commands;

command become => sub {
    my ($universe, $you, $args) = @_;
    if ($args eq 'richer') {
        $you->money($you->money + 100);
        return sprintf("You now have %s %s.",
            $you->money, $universe->money_unit_plural);
    }

    if ($args eq 'deadlier') {
        $you->damage($you->damage + 5);
        return sprintf("Your base damage is now %s.",
            $you->damage);
    }

    if ($args eq 'stronger') {
        $you->basestrength($you->basestrength + 10);

        return sprintf("Your base strength is now %s.",
            $you->max_strength);
    }
};

__PACKAGE__->meta->make_immutable;
1;

