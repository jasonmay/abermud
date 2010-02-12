#!/usr/bin/env perl
package AberMUD::Input::Command::West;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    my $direction = 'west';
    return "You are somehow nowhere." unless defined $you->location;
    return $you->${\"go_$direction"};
}

__PACKAGE__->meta->make_immutable;

1;
