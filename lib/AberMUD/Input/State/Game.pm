#!/usr/bin/env perl
package AberMUD::Input::State::Game;
use Moose;
extends 'AberMUD::Input::State';
use AberMUD::Input::Dispatcher;
use Module::Pluggable
    search_path => ['AberMUD::Input::Command'],
    sub_name    => 'commands',
    require     => 1;

sub welcome_message { "\e[2J" . << '_STOP_';
    _    _               __  __ _   _ ____
   / \  | |__   ___ _ __|  \/  | | | |  _ \
  / _ \ | '_ \ / _ \ '__| |\/| | | | | | | |
 / ___ \| |_) |  __/ |  | |  | | |_| | |_| |
/_/   \_\_.__/ \___|_|  |_|  |_|\___/|____/




The game starts now!
_STOP_
}

has '+entry_message' => (
    default => welcome_message(),
);

has dispatcher => (
    is => 'rw',
    isa => 'AberMUD::Input::Dispatcher',
    default => sub { AberMUD::Input::Dispatcher->new },
);

sub BUILD {
    my $self = shift;

    foreach my $command (sort $self->commands) {
        my $command_object = $command->new;
        $self->dispatcher->add_rule(
            AberMUD::Input::Dispatcher::Rule->new(
                command => $command_object,
                block  => $command_object->can('run'),
            )
        );
    }
}

sub run {
    my $self = shift;
    my ($you, $input) = @_;

    my $dispatch = $self->dispatcher->dispatch($input);

    return "I don't know any commands by that name.\n"
        unless $dispatch->has_matches;

     my $match = ($dispatch->matches)[0];
     return $match->run($you, $match->leftover);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
