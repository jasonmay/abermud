#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;
use AberMUD::Directory;
use KiokuDB;
use AberMUD::Test::Container;
use AberMUD::Input::State::Login::Name;
use AberMUD::Input::State::Game;

my $c = AberMUD::Test::Container->new(
    test_directory => AberMUD::Directory->new(
        kdb => KiokuDB->connect(
            'dbi:SQLite:dbname=t/etc/kdb/001',
        )
    )
)->container;

sub player_joins_game {
    my $p = $c->fetch('player')->get;
    $p->input_state([
        map {
            eval "require $_";
            $_->new(universe => $c->fetch('universe')->get)
        } qw(
        AberMUD::Input::State::Login::Name
        AberMUD::Input::State::Game)
    ]);

    return $p;
}

#sub player_logs_in {
#    my $p = shift;
#
#}

# test the test stuff first..
ok(!%{$c->fetch('universe')->get->players});
my $p1 = player_joins_game();
ok(%{$c->fetch('universe')->get->players});

my $p2 = player_joins_game();
my $p3 = player_joins_game();

is_deeply($c->fetch('universe')->get->players, +{1 => $p1, 2 => $p2, 3 => $p3});

my $beginning_state = $p1->input_state->[0];
my $response        = $p1->types_in('foo');


is(
    $response, $p1->input_state->[0]->entry_message,
    'player is given response message'
);

isnt($beginning_state, $p1->input_state->[0], 'change player input state');
is($p1->input_state->[0]->meta->name, 'AberMUD::Input::State::Login::Password::New');

$p1->types_in('123456'); #enter password
is($p1->input_state->[0]->meta->name, 'AberMUD::Input::State::Login::Password::Confirm');

$p1->types_in('123456'); #re-enter password
is($p1->input_state->[0]->meta->name, 'AberMUD::Input::State::Game');
ok($c->fetch('directory')->get->lookup('player-foo'), 'player stored in kioku');

ok(%{ $c->fetch('universe')->get->players_in_game });


SKIP: {
    my $loc = $c->fetch('directory')->get->lookup('location-test1');
    skip 'missing locations in test kdb', 1 unless $loc;

    $p1->location($loc);

    like(
        $p1->types_in("look"), qr{A road},
        'player tries to see a road'
    ); #look
}

$c->fetch('directory')->get->kdb->delete($p1);
