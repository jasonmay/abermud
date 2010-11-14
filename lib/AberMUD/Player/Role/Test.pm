#!/usr/bin/env perl
package AberMUD::Player::Role::Test;
use Moose::Role;
use AberMUD::Util;

requires qw(setup universe id name);

has output_queue => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

sub add_output { push @{ shift->output_queue }, @_ }
sub get_output { shift @{ shift->output_queue } }
sub clear_output { shift->output_queue([]) };

sub setup { 'stub' }

around materialize => sub {
    my $orig = shift;
    my $self = shift;

    my $id = $self->id;
    my $p = $self->$orig(@_) || return;

    $self->universe->players->{$id} = $p;

    return $p;
};

sub types_in {
    my $self    = shift;
    my $command = shift;

    return unless $self->id;

    return AberMUD::Util::strip_color(
        $self->universe->_controller->build_response(
            $self->id => $command
        )
    );
}

sub leaves_game {
    my $self = shift;
    my $id   = $self->id   || return;
    my $name = $self->name || return;

    delete $self->universe->players->{$id};
    delete $self->universe->players_in_game->{$name};
}

1;

