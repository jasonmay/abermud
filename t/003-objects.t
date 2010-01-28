#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use KiokuDB;
use AberMUD::Container;
use AberMUD::Directory;
use AberMUD::Input::State::Game;

TODO: {
    local $TODO =  'objects do not load from Kioku yet';
    my $c = AberMUD::Container->new_with_traits(
        traits         => ['AberMUD::Container::Role::Test'],
        test_directory => AberMUD::Directory->new(
            kdb => KiokuDB->connect(
                'dbi:SQLite:dbname=t/etc/kdb/003',
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

    like($one->types_in('look'), qr{A rock is laying on the ground here\.});
}