#!/usr/bin/env perl
package AberMUD::Controller::Role::Test;
use Moose::Role;
use namespace::autoclean;

my @methods_to_stub = qw(
    _build_socket
    _build_read_set
    tick
    run
);
__PACKAGE__->can($_) && override($_ => sub { }) for @methods_to_stub;

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

override multisend => sub {
    my $self = shift;
    my %messages = @_;

    while (my ($id, $message) = each %messages) {
        $self->send($id => $message);
    }
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

