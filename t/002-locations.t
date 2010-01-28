#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use AberMUD::Container;

my $c = AberMUD::Container->new_with_traits(
    traits         => ['AberMUD::Container::Role::Test'],
    test_directory => AberMUD::Directory->new(
        kdb => KiokuDB->connect(
            'dbi:SQLite:dbname=t/etc/kdb/002',
        )
    )
)->container;

my $u = $c->fetch('universe')->get;
