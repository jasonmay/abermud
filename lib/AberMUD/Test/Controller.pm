#!/usr/bin/env perl
package AberMUD::Test::Controller;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Controller';
use AberMUD::Player;
use AberMUD::Universe;
use AberMUD::Util;
use JSON;
use DDS;

override _mud_start => sub { };

override run => sub { };

override send => sub {
    my $self = shift;
    my ($id, $message) = @_;

    #TODO append to test player's output queue
};

__PACKAGE__->meta->make_immutable;

1;
