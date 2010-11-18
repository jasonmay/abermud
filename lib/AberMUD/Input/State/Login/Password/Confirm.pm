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
    my ($you, $pass) = @_;
    my $output = q{};

    return $self->entry_message unless $pass;
    if (crypt($pass, $you->name) eq $you->password) {
        $you->shift_state;
    }
    else {
        my $enter_new_password
            = $you->get_global_input_state('AberMUD::Input::State::Login::Password::New');

        $you->unshift_state($enter_new_password);
        $output = "That did not match what you originally typed. Please try again.\n";
    }
    return $output . $you->input_state->[0]->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
