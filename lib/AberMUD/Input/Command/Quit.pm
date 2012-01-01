#!/usr/bin/env perl
package AberMUD::Input::Command::Quit;
use AberMUD::OO::Commands;

command quit => sub {
    my ($self, $e) = @_;

    $e->universe->detach_things($e->player);
    $e->player->mark(disconnect => 1);
    return "So long!";
};

__PACKAGE__->meta->make_immutable;

1;
