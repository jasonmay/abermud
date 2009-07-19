#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::Confirm;
use Moose;
use AberMUD::Input::State::Login::Password::New;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please type in that password again to confirm it: ',
);

sub run {
    my $self = shift;
    my ($you, $pass) = @_;
    my $output = q{};

    if (crypt($pass, $you->name) eq $you->password) {
        $you->shift_state;
    }
    else {
        my $enter_new_password
            = AberMUD::Input::State::Login::Password::New->new;

        $you->unshift_state($enter_new_password);
        $output = "That did not match what you originally typed. Please try again.\n";
    }
    return $output . $you->input_state->[0]->entry_message;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
