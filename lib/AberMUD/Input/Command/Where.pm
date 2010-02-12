#!/usr/bin/env perl
package AberMUD::Input::Command::Where;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

sub run {
    my $you  = shift;
    my $output = "$blue_line\n";

    $output .= join(
        "\n"
        => map {
            sprintf("%20s : %s", $_->name, $_->location->id)
        } @{ $you->universe->mobiles }  );

    $output .= "\n$blue_line\n";

    return $output;
}

__PACKAGE__->meta->make_immutable;

1;
