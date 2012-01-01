#!/usr/bin/env perl
package AberMUD::Input::Command::Admin;
use AberMUD::OO::Commands;

command become => sub {
    my ($self, $e) = @_;
    my $args = $e->arguments;
    if ($args eq 'richer') {
        $e->player->money($e->player->money + 100);
        return sprintf("You now have %s %s.",
            $e->player->money, $e->universe->money_unit_plural);
    }

    if ($args eq 'deadlier') {
        $e->player->damage($e->player->damage + 5);
        return sprintf("Your base damage is now %s.",
            $e->player->damage);
    }

    if ($args eq 'stronger') {
        $e->player->basestrength($e->player->basestrength + 10);

        return sprintf("Your base strength is now %s.",
            $e->player->max_strength);
    }
};

__PACKAGE__->meta->make_immutable;
1;

