#!/usr/bin/env perl
package AberMUD::Input::Command::Who;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

my $command_name = lc __PACKAGE__;
$command_name =~ s/.+:://; $command_name =~ s/\.pm//;
has '+name' => ( default => $command_name );

sub run {
    my $you  = shift;

    return join "\n" => keys %{$you->universe->players_in_game};
}

__PACKAGE__->meta->make_immutable;

1;
