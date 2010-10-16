#!/usr/bin/env perl
use strict;
use warnings;
use lib 'dep/mud/lib';
use lib 'dep/mud/dep/iomi/lib';
use lib 'lib';
use AberMUD::Container;
use KiokuDB;

my $c = AberMUD::Container->new->container;
if (@ARGV) {
    $c->storage_object->directory(
        KiokuDB->connect(
            "dbi:SQLite:dbname=$ARGV[0]"
        )
    )
}

$c->resolve(service => 'app')->run;
