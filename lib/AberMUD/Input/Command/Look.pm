#!/usr/bin/env perl
package AberMUD::Input::Command::Look;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub sort { -10 }
sub run {
    my $you  = shift;
    return "You are somehow nowhere." unless defined $you->location;
    return $you->look;
}

__PACKAGE__->meta->make_immutable;

1;
