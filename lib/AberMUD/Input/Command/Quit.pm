#!/usr/bin/env perl
package AberMUD::Input::Command::Quit;
use AberMUD::OO::Commands;

command quit => sub {
    my ($universe, $you, $args) = @_;

    $universe->detach_things($you);
    $you->mark(disconnect => 1);
    return "So long!";
};

__PACKAGE__->meta->make_immutable;

1;
