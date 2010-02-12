#!/usr/bin/env perl
package AberMUD::Input::Command::Jump;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;

    return "Wheee...";
}

__PACKAGE__->meta->make_immutable;

1;
