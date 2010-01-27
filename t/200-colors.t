#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 140;
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

is(AberMUD::Util::colorify("&&+Rfoo&&*"), "&+Rfoo&*", "&+Rfoo&*");
is(AberMUD::Util::colorify("&&+Gfoo&&*"), "&+Gfoo&*", "&+Gfoo&*");
is(AberMUD::Util::colorify("&&+Yfoo&&*"), "&+Yfoo&*", "&+Yfoo&*");
is(AberMUD::Util::colorify("&&+Mfoo&&*"), "&+Mfoo&*", "&+Mfoo&*");
is(AberMUD::Util::colorify("&&+Bfoo&&*"), "&+Bfoo&*", "&+Bfoo&*");
is(AberMUD::Util::colorify("&&+Cfoo&&*"), "&+Cfoo&*", "&+Cfoo&*");
is(AberMUD::Util::colorify("&&+Wfoo&&*"), "&+Wfoo&*", "&+Wfoo&*");
is(AberMUD::Util::colorify("&&+rfoo&&*"), "&+rfoo&*", "&+rfoo&*");
is(AberMUD::Util::colorify("&&+gfoo&&*"), "&+gfoo&*", "&+gfoo&*");
is(AberMUD::Util::colorify("&&+yfoo&&*"), "&+yfoo&*", "&+yfoo&*");
is(AberMUD::Util::colorify("&&+mfoo&&*"), "&+mfoo&*", "&+mfoo&*");
is(AberMUD::Util::colorify("&&+bfoo&&*"), "&+bfoo&*", "&+bfoo&*");
is(AberMUD::Util::colorify("&&+cfoo&&*"), "&+cfoo&*", "&+cfoo&*");
is(AberMUD::Util::colorify("&&+wfoo&&*"), "&+wfoo&*", "&+wfoo&*");

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

is(AberMUD::Util::colorify("foo&/bar"), "foo\r\nbar", "newlines");
is(AberMUD::Util::colorify("foo\nbar"), "foo\n\rbar", "lf");

is(AberMUD::Util::colorify("&=RGfooo"), "\e[1;42;31mfooo\e[40m\e[0m", "\e[1;42;31mfooo\e[40m\e[0m");
is(AberMUD::Util::colorify("&&+Rfoo&+Gba&*r"), "&+Rfoo\e[1;32mba\e[40m\e[0mr", "&+Rfoo\e[1;32mba\e[40m\e[0mr");
is(AberMUD::Util::colorify("&+rfah&n"), "\e[0;31mfah\e[40m\e[0m", "\e[0;31mfah\e[40m\e[0m");
is(AberMUD::Util::colorify("&Bfoo&*"), "foo\e[40m\e[0m", "foo\e[40m\e[0m");

is(AberMUD::Util::colorify("&&&&&+++RR&+&++&+&+T&+R&+R&+Gfooooooobaz&*&*"), "&&&+++RR&+&++&+&+T\e[1;31m\e[1;31m\e[1;32mfooooooobaz\e[40m\e[0m\e[40m\e[0m", "&&&+++RR&+&++&+&+T\e[1;31m\e[1;31m\e[1;32mfooooooobaz\e[40m\e[0m\e[40m\e[0m");

is(AberMUD::Util::colorify("&-rhello&*"), "\e[0;41mhello\e[40m\e[0m", "\e[0;41mhello\e[40m\e[0m");
is(AberMUD::Util::colorify("&=GRtesting 1&* 2 &-M3&*"), "\e[1;41;32mtesting 1\e[40m\e[0m 2 \e[1;45m3\e[40m\e[0m", "\e[1;41;32mtesting 1\e[40m\e[0m 2 \e[1;45m3\e[40m\e[0m");
is(AberMUD::Util::colorify("&-Gfoo"), "\e[1;42mfoo\e[40m\e[0m", "\e[1;42mfoo\e[40m\e[0m");
is(AberMUD::Util::colorify("&=RGfooo"), "\e[1;42;31mfooo\e[40m\e[0m", "\e[1;42;31mfooo\e[40m\e[0m");

is(AberMUD::Util::colorify("&+Rfoo&#cool"), "\e[1;31mfoocool\e[40m\e[0m", "\e[1;31mfoocool\e[40m\e[0m");

is(AberMUD::Util::colorify("&+Rfoo&Ncool"), "\e[1;31mfoo\e[40m\e[0mcool", "\e[1;31mfoo\e[40m\e[0mcool");
is(AberMUD::Util::colorify("&+Rfoo&ncool"), "\e[1;31mfoo\e[40m\e[0mcool", "\e[1;31mfoo\e[40m\e[0mcool");
