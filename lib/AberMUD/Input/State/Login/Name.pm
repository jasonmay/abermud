#!/usr/bin/env perl
package AberMUD::Input::State::Login::Name;
use Moose;

use AberMUD::Input::State::Login::Password;

with 'AberMUD::Input::State';

sub entry_message { 'Please enter your name: ' }

sub run {
    my $self = shift;
    my ($controller, $conn, $name) = @_;
    $name = lc $name;

    return $self->entry_message unless $name;

    $conn->name_buffer($name);
    $conn->associated_player($conn->storage->player_lookup($name));
    if ($conn->has_associated_player) {

        # replace current state (this) with asking for the password
        my $state = 'AberMUD::Input::State::Login::Password';
        $conn->input_states->[0]
            = $controller->input_states->{$state};
    }
    else {
        # trash this state and add some new ones
        shift @{$conn->input_states};
        unshift @{$conn->input_states},
        map { $controller->input_states->{$_} }
        qw/
            AberMUD::Input::State::Login::Password::New
            AberMUD::Input::State::Login::Password::Confirm
        /;
}

    return $conn->input_state->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
