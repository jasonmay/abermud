#!/usr/bin/env perl
package AberMUD::Input::Command::Up;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    my $direction = 'up';
    return "You are somehow nowhere." unless defined $you->location;
    return $you->${\"go_$direction"};
}

__PACKAGE__->meta->make_immutable;

1;
