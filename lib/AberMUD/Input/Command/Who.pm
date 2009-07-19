#!/usr/bin/env perl
package AberMUD::Input::Command::Who;
use Moose;
extends 'AberMUD::Input::Command';

has '+name' => ( default => 'who' );

sub run {
#    my $self = shift;
    my $you  = shift;
#    my $args = shift;
    return join(" " => map { ref || $_ } @_);
#    return join "\n" => keys %{$you->universe->players_in_game};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
