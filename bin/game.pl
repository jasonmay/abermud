#!/usr/bin/env perl
# PODNAME: game.pl

use strict;
use warnings;
use lib 'lib', 'extlib';
use AberMUD;
use KiokuDB;

my $abermud = AberMUD->new;
if (@ARGV) {
    $abermud->storage_object->directory(
        KiokuDB->connect(
            "dbi:SQLite:dbname=$ARGV[0]"
        )
    )
}

warn "running...";
$abermud->run;
