#!/usr/bin/env perl
package AberMUD::Universe;
use Moose;
extends 'MUD::Universe';
use Scalar::Util qw(weaken);
use KiokuDB;
use KiokuDB::Backend::DBI;

has directory => (
    is  => 'rw',
    isa => 'KiokuDB',
    default => sub {
        KiokuDB->connect('dbi:SQLite:dbname=abermud', create => 1, serialize => 'yaml')
    },
);

has directory_scope => (
    is  => 'rw',
    isa => 'KiokuDB::LiveObjects::Scope',
);

has players_in_game => (
    is  => 'rw',
    isa => 'HashRef[AberMUD::Player]',
    default => sub { +{} },
);

sub BUILD {
    my $self = shift;
    $self->directory_scope($self->directory->new_scope);
}

sub load_player {
    my $self = shift;
    my $player = shift;
    my %args = @_;

}

1;
