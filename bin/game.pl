#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Container;
use KiokuDB;

my $c = AberMUD::Container->new->container;
if (@ARGV) {
    $c->fetch('storage')->get->directory(
        KiokuDB->connect(
            "dbi:SQLite:dbname=$ARGV[0]"
        )
    )
}

$c->fetch('app')->get->run;
