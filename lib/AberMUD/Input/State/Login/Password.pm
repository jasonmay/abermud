#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password;
use Moose;
extends 'MUD::Input::State';
use AberMUD::Input::State::Game;
use MUD::Input::State;

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

    if ($you->is_saved) {
        if (crypt($pass, lc $you->name) eq $you->password) {
            $you->shift_state;
            return "Welcome!\n";
        }
        else {
            return "Nope. Try again.\nPlease enter your password: ";
        }
    }

}

1;
