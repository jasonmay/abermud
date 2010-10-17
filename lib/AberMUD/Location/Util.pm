#!/usr/bin/env perl
package AberMUD::Location::Util;
use strict;
use warnings;

use List::Util qw(first);

our @directions;
our @direction_letters;

BEGIN {
    @directions = qw(
    north south
    east  west
    up    down
    );
    @direction_letters = qw(
    n s e w u d
    );
}

use Sub::Exporter -setup => {
    exports => [ 'directions', 'direction_letters', 'show_exits' ],
};

sub directions { @directions }
sub direction_letters { @direction_letters }

sub show_exits {
    my %args = @_;
    my $output;
    my %override;

    $output = "&+CObvious exits are:&*\n";
    my $has_exits = 0;
    foreach my $direction ( directions() ) {

        my $exit = $args{universe}->check_exit($args{location}, $direction)
            or next;

        $has_exits = 1;
        my $show_direction = ucfirst $direction;
        $output .= sprintf(
            "%-5s &+Y: &+G%s&*\n",
            $show_direction,
            $exit->title
        );
    }

    $output .= '&+RNone&*' unless $has_exits;
    return $output;
}

1;

