#!/usr/bin/env perl
package AberMUD::Input::Command::Chat;
use Moose;
extends 'AberMUD::Input::Command';

my $command_name = lc __PACKAGE__;
$command_name =~ s/.+:://; $command_name =~ s/\.pm//;
has '+name' => ( default => $command_name );

sub run {
    my $you  = shift;
    return "You try to talk but your mouth has been taped shut!";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
