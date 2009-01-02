#!/usr/bin/env perl
package AberMUD::Input::State::EnterName;
use Moose;
extends 'MUD::Input::State';
use Scalar::Util qw/blessed/;
use AberMUD::Input::State::Game;
use MUD::Input::State;

sub run {
    my $self = shift;
    my ($universe, $you, $name) = @_;
    $name = ucfirst $name;
    $you->name($name);
    push @{$you->input_state}, AberMUD::Input::State::Game->new;
    return "Your name is $name.\n" . $you->prompt->($you);
}

1;
