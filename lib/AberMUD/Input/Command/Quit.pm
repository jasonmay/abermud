#!/usr/bin/env perl
package AberMUD::Input::Command::Quit;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you       = shift;
    my $args      = shift;
    my $txn_id    = shift;

    $you->disconnect(undef, $txn_id);
    return "BYE!";
}

__PACKAGE__->meta->make_immutable;

1;
