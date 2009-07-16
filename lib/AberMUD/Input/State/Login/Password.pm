#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password;
use Moose;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please enter your password: ',
);

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

    if ($you->is_saved) {
        if (crypt($pass, lc $you->name) eq $you->password) {
            $you->shift_state;
            return $you->input_state->[0]->entry_message;
        }
        else {
            return "Nope. Try again.\n" . $self->entry_message;
        }
    }
    else {
        warn "The player should have been saved by this input state";
        $you->disconnect;
    }
}

1;
