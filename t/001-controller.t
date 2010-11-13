#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Storage;
use KiokuDB;
use AberMUD::Zone;
use AberMUD::Container;
use AberMUD::Universe;
use AberMUD::Input::State::Login::Name;
use AberMUD::Input::State::Game;
use AberMUD::Config;

use AberMUD::Test::Sugar qw(build_preset_game);

#my $c = build_container();

my ($c, $locations) = build_preset_game('two_wide');

my $u = $c->resolve(service => 'universe');

# not using login sugar because we want to test
# internals
sub player_joins_game {
    my $p = $c->resolve(service => 'player');
    $p->input_state([
        map {
            eval "require $_";
            $_->new(universe => $c->resolve(service => 'universe'))
        } qw(
        AberMUD::Input::State::Login::Name
        AberMUD::Input::State::Game)
    ]);

    return $p;
}

my $txn_block = sub {

    ok(!%{$u->players});
    my $p1 = player_joins_game();
    ok(%{$u->players});

    ok($p1->get_global_input_state($_), "$_ loaded ok") for qw/
        AberMUD::Input::State::Login::Name
        AberMUD::Input::State::Login::Password
        AberMUD::Input::State::Login::Password::New
        AberMUD::Input::State::Login::Password::Confirm
        AberMUD::Input::State::Game
    /;

    my $p2 = player_joins_game();
    my $p3 = player_joins_game();

    is_deeply($u->players, +{1 => $p1, 2 => $p2, 3 => $p3});

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
    ok($c->storage_object->lookup('player-foo'), 'player stored in kioku');

    ok(%{ $u->players_in_game });

    $p1->leaves_game;

    my $p4 = player_joins_game();

    $p4->types_in('foo');
    is($p4->input_state->[0]->meta->name, 'AberMUD::Input::State::Login::Password');
    $p4->types_in('123465'); # oops, typo the password!
    is($p4->input_state->[0]->meta->name, 'AberMUD::Input::State::Login::Password');
    $p4->types_in('123456');
    is($p4->input_state->[0]->meta->name, 'AberMUD::Input::State::Game');

    $p4 = $p4->dir_player; # server talks to this guy now
    ok($p4->id);

    $p4->types_in('chat sup dudes');

    ok(!@{ $_->output_queue }) for $p1, $p2, $p3, $p4;

    $p2->types_in('bar');
    $p2->types_in('123') for 1..2;

    is($u->players->{2}, $p2);

    $p2->types_in('chat hey');

    like($p4->output_queue->[0], qr{hey}, 'foo saw bar chat "hey"');

};

$c->storage_object->txn_do($txn_block);

done_testing();
