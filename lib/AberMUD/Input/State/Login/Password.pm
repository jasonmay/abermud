#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password;
use Moose;
extends 'MUD::Input::State';
use AberMUD::Input::State::Game;
use MUD::Input::State;

sub run {
    my $self = shift;
    my ($you, $name) = @_;
    $name = lc $name;

    $you->push_state(AberMUD::Input::State::Game->new);

    return "Welcome!\n";
}

1;
