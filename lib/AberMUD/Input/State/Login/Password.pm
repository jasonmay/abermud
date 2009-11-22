#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please enter your password: ',
);

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

    if ($you->dir_player) {
        if (crypt($pass, lc $you->name) eq $you->dir_player->password) {
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

__PACKAGE__->meta->make_immutable;

1;
