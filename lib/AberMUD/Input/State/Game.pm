#!/usr/bin/env perl
package AberMUD::Input::State::Game;
use Moose;
extends 'AberMUD::Input::State';
use AberMUD::Input::Dispatcher;
use AberMUD::Input::Command::Composite;

sub welcome_message { "\e[2J" . << '_STOP_';
&+G    _    _               __  __ _   _ ____&*
&+G   / \  | |__   ___ _ __|  \/  | | | |  _ \&*
&+G  / _ \ | '_ \ / _ \ '__| |\/| | | | | | | |&*
&+G / ___ \| |_) |  __/ |  | |  | | |_| | |_| |&*
&+G/_/   \_\_.__/ \___|_|  |_|  |_|\___/|____/&*

&+B========================================================&*
&+CWelcome to AberMUD!&* This is just a base framework
for other MUDs. So far it has the following features:
  &+R*&* Locations (n/s/e/w/u/d)
  &+R*&* Communication (chat, say)
  &+R*&* Over 4000 rooms
  &+R*&* Over 900 mobiles

&+YTHINGS TO DO&*
  &+Y*&* Fighting
  &+Y*&* Currency
  &+Y*&* Weapons, Armor
  &+Y*&* Quests
  &+Y*&* Command help pages
  &+Y*&* Info
_STOP_
}

has '+entry_message' => (
    default => welcome_message(),
);

has dispatcher => (
    is => 'rw',
    isa => 'AberMUD::Input::Dispatcher',
    default => sub { AberMUD::Input::Dispatcher->new },
    handles => ['dispatch'],
);

sub BUILD {
    my $self = shift;

    foreach my $command_method (AberMUD::Input::Command::Composite->meta->get_all_methods) {
        next unless $command_method->meta->can('does_role');
        next unless $command_method->meta->does_role('AberMUD::Role::Command');


        $self->dispatcher->add_rule(
            AberMUD::Input::Dispatcher::Rule->new(
                command_name => $command_method->name,
                block        => sub {
                    shift; $command_method->body->(@_);
                },

                priority => $command_method->priority,
                aliases  => $command_method->aliases,
            )
        );
    }
}

sub run {
    my $self = shift;
    my ($you, $input, $txn_id) = @_;

    my $dispatch = $self->dispatch($input);

    return "" unless $input =~ /\S/;

    return "I don't know any commands by that name."
        unless $dispatch->has_matches;

     my $match = (sort { $a->rule->priority <=> $b->rule->priority } $dispatch->matches)[0];

     return $match->run($you, $match->leftover, $txn_id);
}

__PACKAGE__->meta->make_immutable;

1;
