#!/usr/bin/env perl
package AberMUD::Player;
use Moose;
use AberMUD::Server;
extends 'MUD::Player';

=head1 NAME

AberMUD::Player - AberMUD Player class for playing

=head1 SYNOPSIS

    my $player = AberMUD::Player->new;

    ...

    $player->save;

=head1 DESCRIPTION

AberMUD's player system is not very nomadic. A player's location and inventory does not stay on that person when he leaves the game. 

=cut

has 'prompt' => (
    is  => 'rw',
    isa => 'CodeRef'
);

has 'universe' => (
    is        => 'rw',
    isa       => 'AberMUD::Universe',
    required  => 1,
    weak_ref  => 1,
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

