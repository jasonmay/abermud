#!/usr/bin/env perl
package AberMUD::Util;
use Moose;
use namespace::autoclean;

sub colorify {
    my $text = shift;

    my %letter_to_ansi = (
        l => 0, L => 0,
        r => 1, R => 1,
        g => 2, G => 2,
        y => 3, Y => 3,
        b => 4, B => 4,
        m => 5, M => 5,
        c => 6, C => 6,
        W => 7, w => 7,
    );

    # &+X
        $text =~ s|(?<!&)&\+([rgybmcw])|\e[0;3$letter_to_ansi{$1}m|g;
        $text =~ s|(?<!&)&\+([RGYBMCW])|\e[1;3$letter_to_ansi{$1}m|g;

    # &-X
    $text =~ s|(?<!&)&-([rgybmcw])|\e[0;4$letter_to_ansi{$1}m|g;
    $text =~ s|(?<!&)&-([RGYBMCW])|\e[1;4$letter_to_ansi{$1}m|g;

    # &=X
    $text =~ s|
        (?<!&) & = ([rgybmcw]) ([RGYBMCWrgybmcw])
    |"\e[0;4$letter_to_ansi{$2};3$letter_to_ansi{$1}m"|gex;

    # &=X
    $text =~ s|
        (?<!&) & = ([RGYBMCW]) ([RGYBMCWrgybmcw])
    |"\e[1;4$letter_to_ansi{$2};3$letter_to_ansi{$1}m"|gex;

    $text =~ s{\n(?!\r)}{\n\r}g;
    $text =~ s{(?<!&)&/}{\r\n}g;
    $text =~ s/(?<!&)&\*/\e[40m\e[0m/g;
    $text =~ s/(?<!&)&[nN]/\e[40m\e[0m/g;

    my @tokens = split /\e\[40m\e\[0m/, $text;

    $text =~ s/(?<!\e\[40m\e\[0m)$/\e[40m\e[0m/
        if @tokens and $tokens[-1] =~ /\e/;


    # don't support blinking and bells :)
    $text =~ s/&[B#]//g;

    $text =~ s/&[^+]/&/g;

    return $text;
}

sub strip_color {
    my $text = shift;
    $text =~ s/\e\[.+?[a-zA-Z]//g;

    return $text;
}

#sub dsn { 'bdb:dir=abermud.bdb' }
sub dsn { 'dbi:SQLite:dbname=abermud' }

__PACKAGE__->meta->make_immutable;

1;

