#!/usr/bin/env perl
package AberMUD::Input::Command::Jump;
use AberMUD::OO::Commands;

command jump => sub {
    my $you  = shift;

    return "Wheee...";
}

__PACKAGE__->meta->make_immutable;

1;
