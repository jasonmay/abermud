#!/usr/bin/env perl
package AberMUD::Input::Command::Chat;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

has '+alias' => ( default => '0' );

sub run {
    my $you  = shift;
    my $args  = shift;
    my $message = sprintf("&+M[Chat] %s:&* %s", $you->name, $args);
    $you->universe->broadcast($message, except => $you);

    return $message;
}

__PACKAGE__->meta->make_immutable;

1;
