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
    my @objects = grep {
    $_->location
        and $_->location == $args{location}
            and $_->does('AberMUD::Object::Role::Gateway')
    } @{$args{universe}->objects};
    $output = "&+CObvious exits are:&*\n";
    my $has_exits = 0;
    foreach my $direction ( directions() ) {
        my $exit;
        my $link = "${direction}_link";
        my $obj = first {
            defined($_->$link)
                and $_->openable and $_->opened
        } @objects;
        $exit =   $obj->$link->location if $obj;
        $exit ||= $args{location}->$direction;

        next unless $exit;

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

