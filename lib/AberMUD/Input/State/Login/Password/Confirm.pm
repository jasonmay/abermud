#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::Confirm;
use Moose;
extends 'MUD::Input::State';
use AberMUD::Input::State::Game;
use MUD::Input::State;

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

        $you->confirmed_password($pass);

        $you->shift_state;
        return "Please verify this password by retyping it: ";
}

1;
