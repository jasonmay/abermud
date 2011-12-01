#!/usr/bin/env perl
package AberMUD::Input::Command::Quit;
use AberMUD::OO::Commands;

command quit => sub {
    my ($universe, $you, $args) = @_;

    $you->mark(disconnect => 1);
    return "BYE!";
};

__PACKAGE__->meta->make_immutable;

1;
