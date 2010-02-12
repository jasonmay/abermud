#!/usr/bin/env perl
package AberMUD::Input::Command::North;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    my $direction = 'north';
    return "You are somehow nowhere." unless defined $you->location;
    return $you->${\"go_$direction"};
}

__PACKAGE__->meta->make_immutable;

1;
