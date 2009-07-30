#!/usr/bin/env perl
package AberMUD::Input::Command::Who;
use Moose;
extends 'AberMUD::Input::Command';

has '+name' => ( default => 'who' );

sub run {
    my $you  = shift;

    return join "\n" => keys %{$you->universe->players_in_game};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
