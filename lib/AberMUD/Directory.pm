#!/usr/bin/env perl
package AberMUD::Directory;
use Moose;
use KiokuDB;
use namespace::autoclean;

has kdb => (
    is => 'ro',
    isa => 'KiokuDB',
    lazy_build => 1,
    handles => [ qw/store lookup search update/ ],
);

sub _build_kdb {
    #this can't POSSIBLY be right
    KiokuDB->connect('dbi:SQLite:dbname=abermud', create => not -f 'abermud')
}

has scope => (
    is      => 'rw',
    isa     => 'KiokuDB::LiveObjects::Scope',
    builder => '_build_scope',
);

sub player_lookup {
    my $self = shift;
    my $name = shift;
    return $self->lookup("player-$name");
}

sub _build_scope {
    my $self = shift;
    $self->kdb->new_scope;
}

__PACKAGE__->meta->make_immutable;

1;

