#!/usr/bin/env perl
package AberMUD::Server;
use Moose;
use MooseX::POE;
extends 'MUD::Server';
use AberMUD::Player;
use AberMUD::Universe;
use POE::Session;
use POE::Kernel;

has player_data_path => (
    is  => 'rw',
    isa => 'Str',
    default => "$ENV{PWD}/data"
);

has '+universe' => (
    isa => 'AberMUD::Universe'
);

sub spawn_player {
    my $self     = shift;
    my $id       = shift;
    my $universe = shift;
    return AberMUD::Player->new(
        id => $id,
        prompt => "\e[1;33m\$\e[0m ",
        input_state => [
        map { eval "require $_"; $_->new }
        qw(
        AberMUD::Input::State::Login::Name
        AberMUD::Input::State::Game
        )
        ],
        universe => $universe,
    );
}

around '_response' => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $player = $self->universe->players->{$id};

    my $response = $self->$orig($id, @_);
    return "You are in a void of nothingness...\n"
    unless @{$player->input_state};

    if (ref $player->input_state->[0] eq 'AberMUD::Input::State::Game') {
        $player->materialize;
        my $prompt = $player->prompt;
        return "$response\n$prompt";
    }
    return $response;
};

around 'START' => sub {
    my $orig = shift;
    my ($self, $kernel, $session) = @_[0, KERNEL, SESSION];
    $kernel->delay(tick => 1);
};

event 'tick' => sub {
    $_[KERNEL]->delay(tick => 1);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
