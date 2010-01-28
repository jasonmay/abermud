#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use AberMUD::Container;
use AberMUD::Input::State::Game;

my $c = AberMUD::Container->new_with_traits(
    traits         => ['AberMUD::Container::Role::Test'],
    test_directory => AberMUD::Directory->new(
        kdb => KiokuDB->connect(
            'dbi:SQLite:dbname=t/etc/kdb/002',
        )
    )
)->container;

my $u = $c->fetch('universe')->get;

sub player_logs_in {
    my $p = $c->fetch('player')->get;
    $p->input_state([AberMUD::Input::State::Game->new]);

    $p->name(shift);
    $p->location($c->fetch('directory')->get->lookup('location-test1'));
    $p->_join_game;
}

my $one = player_logs_in('playerone');
my $two = player_logs_in('playertwo');

like($one->types_in('look'), qr{playertwo is standing here}i);
