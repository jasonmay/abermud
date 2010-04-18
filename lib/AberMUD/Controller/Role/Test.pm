#!/usr/bin/env perl
package AberMUD::Controller::Role::Test;
use Moose::Role;
use namespace::autoclean;

__PACKAGE->can('_mud_start') && override _mud_start => sub { };

override run => sub { };

override send => sub {
    my $self = shift;
    my ($id, $message) = @_;

    return unless $id;

    my $p = $self->universe->players->{$id} or return;
    if (!$p->does('AberMUD::Player::Role::Test')) {
        warn "not a test player";
        return;
    }

    $p->add_output($message);
};

override force_disconnect => sub {
    my $self = shift;
    my $id   = shift;

    return unless $id;

    my $p = $self->universe->players->{$id} or return;
    return unless $p->does('AberMUD::Player::Role::Test');

    $p->leaves_game;
};

1;

