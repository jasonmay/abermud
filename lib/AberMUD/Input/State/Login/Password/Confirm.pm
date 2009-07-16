#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::Confirm;
use Moose;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please type in that password again to confirm it: ',
);

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

    $you->confirmed_password($pass);

    $you->shift_state;
    return $you->input_state->[0]->entry_message;
}

1;
