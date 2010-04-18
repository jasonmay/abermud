#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use AberMUD::Directory;
use KiokuDB;
use AberMUD::Zone;
use AberMUD::Container;
use AberMUD::Input::State::Login::Name;
use AberMUD::Input::State::Game;

my $kdb = KiokuDB->connect('dbi:SQLite:dbname=:memory:', create => 1);
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

    my $scope = $kdb->new_scope;
    $kdb->store("location-$_" => $locations{$_}) foreach keys %locations;

    $locations{test1}->north($locations{test2});
    $locations{test2}->south($locations{test1});

    $kdb->update($_) foreach values %locations;
}

my $c = AberMUD::Container->new_with_traits(
    traits         => ['AberMUD::Container::Role::Test'],
    test_directory => AberMUD::Directory->new(
        kdb => $kdb,
    )
)->container;

my $u = $c->fetch('universe')->get;

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

my $txn_block = sub {
    ok(!%{$u->players});
    my $p1 = player_joins_game();
    ok(%{$u->players});

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
    ok($c->fetch('directory')->get->lookup('player-foo'), 'player stored in kioku');

    ok(%{ $u->players_in_game });


    SKIP: {
        my $loc = $c->fetch('directory')->get->lookup('location-test1');
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

$c->fetch('directory')->get->kdb->txn_do($txn_block)
