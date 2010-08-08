#!/usr/bin/env perl
package AberMUD::Input::Command::Look;
use AberMUD::OO::Commands;

command 'look', alias => -10, sub {
    my $you  = shift;
    return "You are somehow nowhere." unless defined $you->location;
    return $you->look;
};

__PACKAGE__->meta->make_immutable;

1;
