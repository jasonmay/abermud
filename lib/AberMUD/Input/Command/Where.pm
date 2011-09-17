#!/usr/bin/env perl
package AberMUD::Input::Command::Where;
use AberMUD::OO::Commands;

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

command where => sub {
    my ($universe, $you, $args) = @_;
    my $output = "$blue_line\n";

    $output .= join(
        "\n"
        => map {
            sprintf("%20s : %s", $_->name, $_->location->id)
        } grep { $_->location and $_->name eq $args } $you->universe->get_mobiles
    );

    $output .= join(
        "\n"
        => map {
            sprintf("%20s : %s", $_->name, $_->location->id)
        } grep { $_->location and $_->name eq $args } $you->universe->get_objects
    );

    $output .= "\n$blue_line\n";

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
