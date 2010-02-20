#!/usr/bin/env perl
package AberMUD::Location::Util;
use strict;
use warnings;

our @directions;

BEGIN {
    @directions = qw(
    north south
    east  west
    up    down
    );
}

use Sub::Exporter -setup => {
    exports => [ 'directions' ],
};

sub directions { @directions }

1;

