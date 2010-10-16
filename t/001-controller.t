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

use AberMUD::Test::Sugar qw(build_container);

my $c = build_container();

{
    my $zone = AberMUD::Zone->new(name => 'test');

    my %locations = (
        test1 => AberMUD::Location->new(
            world_id    => 'test1',
            id          => 'road',
            title       => 'A road',
            description => "There is a road here heading north. "
                        . "You hear noises in the distance. ",
            zone        => $zone,
            active      => 1,
        ),
        test2 => AberMUD::Location->new(
            world_id    => 'test2',
            id          => 'path',
            title       => 'Path',
            description => "This path goes north and south.",
            zone        => $zone,
            active      => 1,
        ),
    );

    my $storage = $c->storage_object;
    $storage->store("location-$_" => $locations{$_}) foreach keys %locations;

    $locations{test1}->north($locations{test2});
    $locations{test2}->south($locations{test1});

    $storage->update($_) foreach values %locations;

    my $config = AberMUD::Config->new(
        input_states => [qw(Login::Name Game)],
        universe => AberMUD::Universe->new,
    );

    $storage->store(config => $config);

    $config->location($locations{test1});
    $storage->update($config);
}

my $u = $c->resolve(service => 'universe');

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


    SKIP: {
        my $loc = $c->storage_object->lookup('location-test1');
        skip 'missing locations in test kdb', 1 unless $loc;

        $p1->location($loc);

        like(
            $p1->types_in("look"), qr{A road},
            'player tries to see a road'
        ); #look
    }

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
