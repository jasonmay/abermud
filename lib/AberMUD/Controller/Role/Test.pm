#!/usr/bin/env perl
package AberMUD::Controller::Role::Test;
use Moose::Role;
use namespace::autoclean;

override _mud_start => sub { };

override run => sub { };

override send => sub {
    my $self = shift;
    my ($id, $message) = @_;

    return unless $id;

    my $p = $self->universe->players->{$id};
    if (!$p) {
        #warn "$id => $message";
        return;
    }
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

    my $p = $self->universe->players->{$id};
    if (!$p) {
        warn $id;
        return;
    }
    return unless $p->does('AberMUD::Player::Role::Test');

    $p->leaves_game;
};

1;

