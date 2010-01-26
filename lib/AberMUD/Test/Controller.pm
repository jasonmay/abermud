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

override _mud_start => sub {
    # warn "override"
};

override run => sub { }; # make run not do anything

__PACKAGE__->meta->make_immutable;

1;
