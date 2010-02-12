#!/usr/bin/env perl
package AberMUD::Input::Command::Quit;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    $you->disconnect;
    return "";
}

__PACKAGE__->meta->make_immutable;

1;
