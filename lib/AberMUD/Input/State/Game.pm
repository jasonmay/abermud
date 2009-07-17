#!/usr/bin/env perl
package AberMUD::Input::State::Game;
use Moose;
extends 'AberMUD::Input::State';
use DDS;

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

has dispatch => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub {
        return +{
            look => sub { "You see stuff.\n" },
            whoami => sub {
                my $you = shift;
                return "Your name is " . $you->name;
            },

            (map {
                my $dir = $_;
                ($dir => sub { "You try to go $dir but the MUD sucks!\n" });
            }
            qw/north south east west up down/),
            save => sub {
                my $you = shift;
                $you->save_data;
                return "Saved!\n";
            },
            who => sub {
                my $you = shift;
                join("\n" =>
                    keys %{ $you->universe->players_in_game })
            },
            prompt => sub {
                my $you = shift;
                my $args = shift;

                $you->prompt($args);
            },
            quit => sub {
                my $you = shift;

                $you->disconnect;
            },
        }
    }
);

has universe => (
    is  => 'rw',
    isa => 'AberMUD::Universe',
);

sub run {
    my $self = shift;
    my ($you, $input) = @_;

    # first word of the user input
    my @words = split ' ', $input;
    my $command = lc shift(@words);
    my $args = join ' ', @words;
    my $dispatch = $self->dispatch;
    my $output =
        exists $dispatch->{$command}
            ? $dispatch->{$command}->($you, $args)
            : "Sorry, I don't understand!";
    return "$output";
}

1

