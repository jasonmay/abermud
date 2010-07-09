#!/usr/bin/env perl
package AberMUD::Input::State::Game;
use Moose;
extends 'AberMUD::Input::State';
use AberMUD::Input::Dispatcher;
use AberMUD::Input::Commands;
#use Module::Pluggable
#    search_path => ['AberMUD::Input::Command'],
#    sub_name    => 'commands',
#    require     => 1;

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
);

sub BUILD {
    my $self = shift;

    my $commands = AberMUD::Input::Commands->new;
    foreach my $command_class ($commands->commands) {
        (my $command = lc $command_class) =~ s/.+:://;

        Class::MOP::load_class($command_class);
        $self->dispatcher->add_rule(
            AberMUD::Input::Dispatcher::Rule->new(
                command => $command_class->new,
                block   => sub { $commands->$command(@_) },
            )
        );
    }
}

sub run {
    my $self = shift;
    my ($you, $input, $txn_id) = @_;

    my $dispatch = $self->dispatcher->dispatch($input);

    return "" unless $input =~ /\S/;

    return "I don't know any commands by that name."
        unless $dispatch->has_matches;

     my $match = (sort { $a->rule->command->sort <=> $b->rule->command->sort } $dispatch->matches)[0];
     return $match->run($you, $match->leftover, $txn_id);
}

__PACKAGE__->meta->make_immutable;

1;
