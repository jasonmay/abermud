#!/usr/bin/env perl
package AberMUD::Input::State::Login::Name;
use Moose;
extends 'AberMUD::Input::State';
use AberMUD::Input::State::Login::Password;

has '+entry_message' => (
    default => 'Please enter your name: ',
);

sub run {
    my $self = shift;
    my ($you, $name) = @_;
    $name = lc $name;

    $you->name($name);
    if ($you->is_saved) {
        $you = $you->load_data;
        $you->input_state->[0]
            = AberMUD::Input::State::Login::Password->new;
    }
    else {
        # trash this state and add some new ones
        $you->shift_state; #$you->shift_state;
        $you->unshift_state(
            map { eval "require $_"; $_->new } qw(
                AberMUD::Input::State::Login::Password::New
                AberMUD::Input::State::Login::Password::Confirm
            )
        );
    }

    return $you->input_state->[0]->entry_message;
}

1;
