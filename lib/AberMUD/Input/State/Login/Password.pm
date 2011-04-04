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
    my ($controller, $conn, $pass) = @_;

    return $self->entry_message unless $pass;
    if (my $player = $conn->associated_player) {
        my $crypted = crypt($pass, lc $player->name);
        if ($crypted eq $player->password) {
            $player->location($controller->storage->lookup_default_location);
            $conn->shift_state;
            return $conn->input_state->entry_message;
        }
        else {
            return "Nope. Try again.\n" . $self->entry_message;
        }
    }
    else {
        warn "The player should have been saved by this input state";
        $conn->disconnect;
    }
}

__PACKAGE__->meta->make_immutable;

1;
