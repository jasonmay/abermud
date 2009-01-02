#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
use AberMUD::Server;
extends 'MUD::Player';

has 'prompt' => (
    is  => 'rw',
    isa => 'CodeRef'
);

has 'universe' => (
    is   => 'rw',
    isa  => 'AberMUD::Universe',
    requires => 1
);

sub save {
    my $self = shift;
    warn "This should really do stuff, huh.";
}

sub make_save_file {
    
}

sub disconnect {
    
}

1;

