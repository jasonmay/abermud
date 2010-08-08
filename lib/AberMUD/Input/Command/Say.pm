#!/usr/bin/env perl
package AberMUD::Input::Command::Say;
use AberMUD::OO::Commands;

command 'say', alias => q['], sub {
    my $you  = shift;
    my $args  = shift;
    my $output = q{};

    $you->say(
        $you->name . " says &+Y'$args'&*\n",
        except => $you,
    );

    return "You say, &+Y'$args'";
};

__PACKAGE__->meta->make_immutable;

1;
