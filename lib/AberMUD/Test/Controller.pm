#!/usr/bin/env perl
package AberMUD::Test::Controller;
use Moose;
use namespace::autoclean;
extends 'MUD::Controller';
use AberMUD::Player;
use AberMUD::Universe;
use AberMUD::Util;
use JSON;
use DDS;

override _mud_start => sub {
    # warn "override"
};

override run => sub { }; # make run not do anything

around '_response' => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $player = $self->universe->players->{$id};

    my $response = $self->$orig($id, @_);
    my $output;

    $output = "You are in a void of nothingness...\n"
        unless $player && @{$player->input_state};

    if ($player && ref $player->input_state->[0] eq 'AberMUD::Input::State::Game') {
        $player->materialize;
        my $prompt = $player->prompt;
        $output = "$response$prompt";
    }
    else {
        $output = $response;
    }

    return AberMUD::Util::colorify($output);
};

around 'perform_connect_action' => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $result = $self->$orig(@_);

    return $result if $data->{param} ne 'connect';

    my $id = $data->{data}->{id};
    return to_json(
        {
            param => 'output',
            data => {
                id    => $id,
                value => $self->universe->players->{$id}->input_state->[0]->entry_message,
            }
        }
    );

};

before 'perform_input_action' => sub {
    my $self = shift;
    my ($data) = @_;

};

around 'perform_disconnect_action' => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $u = $self->universe;
    my $player = $self->universe->players->{ $data->{data}->{id} };
    if ($player && exists $u->players_in_game->{$player->name}) {
        $player->disconnect;
        $player->dematerialize;

        $u->broadcast($player->name . " disconnected.\n")
            unless $data->{data}->{ghost};

        $player->shift_state;
    }

    my $result = $self->$orig(@_);

    return $result;
};

#sub START {
#    my $orig = shift;
#    my ($self, $kernel, $session) = @_[0, KERNEL, SESSION];
#    $kernel->delay(tick => 1);
#};

__PACKAGE__->meta->make_immutable;

1;
