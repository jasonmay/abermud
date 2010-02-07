#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use KiokuDB;
use AberMUD::Container;
use AberMUD::Directory;
use AberMUD::Input::State::Game;

my $c = AberMUD::Container->new_with_traits(
    traits         => ['AberMUD::Container::Role::Test'],
    test_directory => AberMUD::Directory->new(
        kdb => KiokuDB->connect(
            'dbi:SQLite:dbname=t/etc/kdb/003',
        )
    )
)->container;

my $u = $c->fetch('universe')->get;

$c->fetch('controller')->get->_load_objects();

sub player_logs_in {
    my $p = $c->fetch('player')->get;
    $p->input_state([AberMUD::Input::State::Game->new]);

    $p->name(shift);
    $p->location($c->fetch('directory')->get->lookup('location-test1'));
    $p->_join_game;
}

ok(my @o = @{$u->objects}, 'objects loaded');
is_deeply(
    [sort map { $_->does('AberMUD::Object::Role::Getable') } @o],
    [0, 1, 1]
);

my %objects = map { $_->name => $_ } @o;

my $one = player_logs_in('playerone');
my $two = player_logs_in('playertwo');

like($one->types_in('look'), qr{A rock is laying on the ground here\.});


like($one->types_in('take rock'), qr{You take the rock\.});
like($two->get_output, qr{playerone picks up a rock\.}i);

is($objects{rock}->held_by, $one);

unlike($one->types_in('look'), qr{A rock is laying on the ground here\.});
