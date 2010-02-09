#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 134;
use AberMUD::Util;

my %colors = (
    r => 1,
    g => 2,
    y => 3,
    b => 4,
    m => 5,
    c => 6,
    w => 7,
);

is(
    AberMUD::Util::colorify( "&&+${_}foo&&*"),
    "&+${_}foo&*"
) for keys %colors;
is(
    AberMUD::Util::colorify("&&+${_}foo&&*"),
    "&+${_}foo&*"
) for map { uc } keys %colors;;

foreach my $bg (keys %colors) {
    foreach my $fg (keys %colors) {
        is(
            AberMUD::Util::colorify("&=${bg}${fg}fooo"),
            "\e[0;4$colors{$fg};3$colors{$bg}mfooo\e[40m\e[0m",
            "\e[0;4$colors{$bg};3$colors{$fg}mfooo\e[40m\e[0m"
        );

        my $uc_fg = uc $fg;
        my $uc_bg = uc $bg;
        is(
            AberMUD::Util::colorify("&=${uc_bg}${uc_fg}fooo"),
            "\e[1;4$colors{$fg};3$colors{$bg}mfooo\e[40m\e[0m",
            "\e[1;4$colors{$bg};3$colors{$fg}mfooo\e[40m\e[0m"
        );
    }
}

foreach my $color (keys %colors) {
    is(
        AberMUD::Util::colorify("&+${color}fooo"),
        "\e[0;3$colors{$color}mfooo\e[40m\e[0m",
        "\e[0;3$colors{$color}mfooo\e[40m\e[0m",
    );

    my $uc_color = uc $color;
    is(
        AberMUD::Util::colorify("&+${uc_color}fooo"),
        "\e[1;3$colors{$color}mfooo\e[40m\e[0m",
        "\e[1;3$colors{$color}mfooo\e[40m\e[0m",
    );
}

is(
    AberMUD::Util::colorify("&+rtest$_"),
    "\e[0;31mfah\e[40m\e[0m",
) for '&*', '&n', '&N';

is(
    AberMUD::Util::colorify("&+rtest${_}trailing"),
    "\e[0;31mfah\e[40m\e[0mtrailing",
) for '&*', '&n', '&N';

is(AberMUD::Util::colorify("foo&/bar"), "foo\r\nbar", "newlines");
is(AberMUD::Util::colorify("foo\nbar"), "foo\n\rbar", "lf");

