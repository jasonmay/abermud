#!/usr/bin/env perl
package AberMUD::Object::Util;
use strict;
use warnings;

our @bodyparts;

BEGIN {
    @bodyparts = qw(
        left_arm
        right_arm
        left_hand
        right_hand

        left_leg
        right_leg
        left_foot
        right_foot

        chest
        back
        neck
        head
    );
}

use Sub::Exporter -setup => {
    exports => [ 'bodyparts' ],
};

sub bodyparts { @bodyparts }

1;

