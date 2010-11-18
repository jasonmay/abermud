#!/usr/bin/env perl
package AberMUD::Input::State::Login::Password::New;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::State';

has '+entry_message' => (
    default => 'Please enter a new password for your character: ',
);

sub run {
    my $self = shift;
    my ($you, $pass) = @_;

    return $self->entry_message unless $pass;

    $you->password(crypt($pass, $you->name));

    $you->shift_state;
    return $you->input_state->[0]->entry_message;
}

__PACKAGE__->meta->make_immutable;

1;
