#!/usr/bin/env perl
package AberMUD::Input::Command::Who;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

sub run {
    my $you  = shift;
    my $output = "$blue_line\n";

    my @names       = $you->universe->game_name_list;
    my $num_players = @names;

    $output .= join(
        "\n"
        => map {
            sprintf('%-10s | %-50s',
                ucfirst(),
                ucfirst() . ' the Player'
            )
        } @names);

    $output .= "\n$blue_line\n";
    my $linking_verb = @names == 1 ? 'is' : 'are';
    my $noun         = @names == 1 ? 'player' : 'players';

    $output .= "There $linking_verb currently &+C$num_players&* $noun in the game.\n";

    return $output;
}

__PACKAGE__->meta->make_immutable;

1;
