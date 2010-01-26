#!/usr/bin/env perl
package AberMUD::Test::Player;
use Moose;
extends 'AberMUD::Player';

override setup => sub { };

# $player->types_in('take sword');
sub types_in {
    my $self    = shift;
    my $command = shift;

    return $self->universe->_controller->_response(
        $self->id => $command
    );
}

1;

