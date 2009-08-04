#!/usr/bin/env perl
package AberMUD::Input::Command::Chat;
use Moose;
extends 'AberMUD::Input::Command';

my $command_name = lc __PACKAGE__;
$command_name =~ s/.+:://; $command_name =~ s/\.pm//;
has '+name' => ( default => $command_name );

has '+alias' => ( default => '0' );

sub run {
    my $you  = shift;
    my $args  = shift;
    my $message = sprintf("&+M[Chat] %s:&* %s", $you->name, $args);
    $you->universe->broadcast($message, except => $you);

    return $message;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
