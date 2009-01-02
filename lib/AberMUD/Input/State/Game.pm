#!/usr/bin/env perl
package AberMUD::Input::State::Game;
use Moose;
extends 'MUD::Input::State';
use DDS;

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

            map {
                my $dir = $_;
                ($dir => sub { "You try to go $dir but the MUD sucks!\n" });
            }
            qw/north south east west up down/
        }
    }
);

has universe => (
    
);
sub run {
    my $self = shift;
    my ($universe, $you, $input) = @_;

    # first word of the user input
    my $command = lc((split ' ', $input)[0]);
    my $dispatch = $self->dispatch;
    my $output =
        exists $dispatch->{$command}
            ? $dispatch->{$command}->($you)
            : "Sorry, I don't understand!";
    my $prompt = $you->prompt->($you);

    return "$output\n$prompt";
}

1;
