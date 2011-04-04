#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::Confirm;
use Moose;
use namespace::autoclean;
use AberMUD::Input::State::Login::Password::New;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please type in that password again to confirm it: ',
);

sub run {
    my $self = shift;
    my ($controller, $conn, $pass) = @_;
    my $output = q{};

    return $self->entry_message unless $pass;

    my $crypted = crypt($pass, $conn->name_buffer);

    if ($crypted eq $conn->password_buffer) {
        $conn->shift_state;

        my $location = $controller->storage->lookup_default_location;

        # save the player here.
        my $player = $controller->new_payer(
            location => $location,
            prompt   => '&*[ &+C%h/%H&* ] &+Y$&* ',
        );

        $controller->storage->save_player($player);
    }
    else {
        # gah these namespaces are long
        my $new_password_state = 'AberMUD::Input::State::Login::Password::New';
        my $enter_new_password
            = $controller->input_states->{$new_password_state};

        $conn->unshift_state($enter_new_password);
        $output = "That did not match what you originally typed. Please try again.\n";
    }
    return $output . $conn->input_state->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
