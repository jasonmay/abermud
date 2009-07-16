#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::New;
use Moose;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please enter a new password for your character: ',
);

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

        $you->password($pass);

        $you->shift_state;
        return $you->input_state->[0]->entry_message;
}

1;
