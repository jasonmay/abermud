#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use AberMUD::Storage;
use KiokuDB;
use AberMUD::Zone;
use AberMUD::Universe;
use AberMUD::Input::State::Login::Name;
use AberMUD::Input::State::Game;
use AberMUD::Config;

use AberMUD::Test::Sugar qw(build_preset_game);

my ($c, $locations) = build_preset_game('two_wide');

my $u = $c->universe;
my $b = $c->controller->backend;

# not using login sugar because we want to test
# internals
sub new_conn {
    my $p = $b->new_connection(
        input_states => [
            map { $c->controller->input_states->{$_} }
            (
                'AberMUD::Input::State::Login::Name',
                'AberMUD::Input::State::Game',
            )
        ],
    );

    return $p;
}

my $txn_block = sub {

    ok(!%{$u->players});
    my $p1 = new_conn();

    ok($c->controller->input_states->{$_}, "$_ constructed ok") for qw/
        AberMUD::Input::State::Login::Name
        AberMUD::Input::State::Login::Password
        AberMUD::Input::State::Login::Password::New
        AberMUD::Input::State::Login::Password::Confirm
        AberMUD::Input::State::Game
    /;

    my $p2 = new_conn();
    my $p3 = new_conn();

    my $beginning_state = $p1->input_state;
    my $response        = $b->inject_input($p1, 'foo');

    is(
        $response, $p1->input_state->entry_message,
        'player is given response message'
    );

    isnt($beginning_state, $p1->input_state, 'change player input state');
    is($p1->input_state->meta->name, 'AberMUD::Input::State::Login::Password::New');

    $b->inject_input($p1, '123456'); #enter password
    is($p1->input_state->meta->name, 'AberMUD::Input::State::Login::Password::Confirm');

    $b->inject_input($p1, '123456'); #re-enter password
    is($p1->input_state->meta->name, 'AberMUD::Input::State::Game');
    ok($c->storage->lookup('player-foo'), 'player stored in kioku');

    ok(%{ $u->players });

    $b->disconnect($p1);

    my $p4 = new_conn();

    $b->inject_input($p4, 'foo');
    is($p4->input_state->meta->name, 'AberMUD::Input::State::Login::Password');
    $b->inject_input($p4, '123465'); # oops, typo the password!
    is($p4->input_state->meta->name, 'AberMUD::Input::State::Login::Password');
    $b->inject_input($p4, '123456');
    is($p4->input_state->meta->name, 'AberMUD::Input::State::Game');
    $b->inject_input($p4, 'chat sup dudes');

    ok(!@{ $_->output_queue }) for $p1, $p2, $p3, $p4;

    $b->inject_input($p2, 'bar');
    $b->inject_input($p2, '123') for 1..2;

    is($u->players->{bar}, $p2->associated_player);

    $b->inject_input($p2, 'chat hey');

    like($p4->output_queue->[0], qr{hey}, 'foo saw bar chat "hey"');

};

$c->storage->txn_do($txn_block);

done_testing();
