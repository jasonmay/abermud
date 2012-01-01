#!/usr/bin/env perl
package AberMUD::Input::State::Game;
use Moose;

use AberMUD::Input::Dispatcher;
use AberMUD::Event::Command;

with 'AberMUD::Input::State';

sub entry_message { "\e[2J" . << '_STOP_';
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

has dispatcher => (
    is => 'rw',
    isa => 'AberMUD::Input::Dispatcher',
    default => sub { AberMUD::Input::Dispatcher->new },
    handles => ['dispatch'],
);

has command_composite => (
    is       => 'ro',
    isa      => 'AberMUD::Input::Command::Composite',
    required => 1,
);

sub BUILD {
    my $self = shift;

    foreach my $command_method ($self->command_composite->meta->get_all_methods) {
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
    my ($controller, $conn, $input, $txn_id) = @_;

    return "" unless $input =~ /\S/;
    my $dispatch = $self->dispatch($input);

    return "I don't know any commands by that name.\n"
        unless $dispatch->has_matches;

     my $match = (sort { $a->rule->priority <=> $b->rule->priority } $dispatch->matches)[0];

     my $event = AberMUD::Event::Command->new(
         universe  => $self->universe,
         player    => $conn->associated_player,
         arguments => $match->leftover,
     );

     return $match->run( $self->command_composite, $event) . "\n";
}

__PACKAGE__->meta->make_immutable;

1;
