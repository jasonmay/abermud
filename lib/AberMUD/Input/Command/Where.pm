#!/usr/bin/env perl
package AberMUD::Input::Command::Where;
use AberMUD::OO::Commands;

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

command where => sub {
    my $you  = shift;
    my $output = "$blue_line\n";

    $output .= join(
        "\n"
        => map {
            sprintf("%20s : %s", $_->name, $_->location->id)
        } grep { $_->location } $you->universe->get_mobiles  );

    $output .= "\n$blue_line\n";

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
