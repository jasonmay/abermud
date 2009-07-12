#!/usr/bin/env perl
package AberMUD::Input::State::Login::Name;
use Moose;
extends 'MUD::Input::State';
use AberMUD::Input::State::Login::Password;
use MUD::Input::State;
use Scalar::Util qw(weaken);

sub run {
    my $self = shift;
    my ($you, $name) = @_;
    $name = lc $name;

    push @{$you->input_state}, AberMUD::Input::State::Login::Password->new;

    $you->name($name);
    $you = $you->load_data;

    return "Please enter your password: ";
}

1;
