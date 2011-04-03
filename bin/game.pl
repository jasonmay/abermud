#!/usr/bin/env perl
# PODNAME: game.pl

use strict;
use warnings;
use lib '../mud/lib';
use lib '../io-multiplex-intermediary/lib';
use lib 'lib';
use AberMUD::Container;
use KiokuDB;

my $abermud = AberMUD->new;
if (@ARGV) {
    $abermud->storage_object->directory(
        KiokuDB->connect(
            "dbi:SQLite:dbname=$ARGV[0]"
        )
    )
}

$abermud->run;
