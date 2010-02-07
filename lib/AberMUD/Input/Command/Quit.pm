#!/usr/bin/env perl
package AberMUD::Input::Command::Quit;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

my $command_name = lc __PACKAGE__;
$command_name =~ s/.+:://; $command_name =~ s/\.pm//;
override _build_name => sub { $command_name };

sub run {
    my $you  = shift;
    $you->disconnect;
    return "";
}

__PACKAGE__->meta->make_immutable;

1;
