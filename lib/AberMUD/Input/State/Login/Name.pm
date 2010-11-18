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

    return $self->entry_message unless $name;

    $you->name($name);
    $you->dir_player($you->universe->storage->player_lookup($name));
    if ($you->dir_player) {
        $you->input_state->[0]
            = $you->get_global_input_state('AberMUD::Input::State::Login::Password');
    }
    else {
        # trash this state and add some new ones
        $you->shift_state;
        $you->unshift_state(
                map { $you->get_global_input_state($_) }
                qw/
                    AberMUD::Input::State::Login::Password::New
                    AberMUD::Input::State::Login::Password::Confirm
                /
            )
    }

    return $you->input_state->[0]->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
