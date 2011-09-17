#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::Confirm;
use Moose;

use AberMUD::Input::State::Login::Password::New;
use Scalar::Util 'weaken';

with 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please type in that password again to confirm it: ',
);

sub run {
    my $self = shift;
    my ($backend, $conn, $pass) = @_;
    my $output = q{};

    return $self->entry_message unless $pass;

    my $crypted = crypt($pass, $conn->name_buffer);

    if ($crypted eq $conn->password_buffer) {
        $conn->shift_state;

        my $location = $backend->storage->lookup_default_location;

        weaken(my $w = $backend);
        my $send = sub {
            my ($id, $message) = @_;

            $w->send($id => $message);
        };

        # save the player here.
        my $player = $conn->create_player(
            name     => $conn->name_buffer,
            password => $conn->password_buffer,
            location => $location,
            prompt   => '&*[ &+C%h/%H&* ] &+Y$&* ',
            send_sub => $send,
        );

        $backend->storage->save_player($player);
    }
    else {
        # gah these namespaces are long
        my $new_password_state = 'AberMUD::Input::State::Login::Password::New';
        my $enter_new_password
            = $conn->input_states->{$new_password_state};

        $conn->unshift_state($enter_new_password);
        $output = "That did not match what you originally typed. Please try again.\n";
    }
    return $output . $conn->input_state->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
