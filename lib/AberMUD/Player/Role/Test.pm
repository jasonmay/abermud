#!/usr/bin/env perl
package AberMUD::Player::Role::Test;
use Moose::Role;

requires qw(setup universe id name);

has output_queue => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => {
        add_output => 'push',
        get_output => 'shift',
    },
);

override setup => sub { };

around materialize => sub {
    my $orig = shift;
    my $self = shift;

    my $id = $self->id;
    $self->$orig(@_);

    # XXX I shouldn't be doing this. it spoils the test
    $self->universe->players->{$id} = $self;
};

sub types_in {
    my $self    = shift;
    my $command = shift;

    return $self->universe->_controller->_response(
        $self->id => $command
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

