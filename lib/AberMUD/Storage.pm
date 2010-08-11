#!/usr/bin/env perl
package AberMUD::Storage;
use Moose;
use KiokuDB;
use Moose::Util qw(apply_all_roles);
use AberMUD::Util;
use KiokuDB::LiveObjects::Scope;
use Carp;
use namespace::autoclean;

extends 'KiokuX::Model';

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
    $self->new_scope;
}

__PACKAGE__->meta->make_immutable;

1;

