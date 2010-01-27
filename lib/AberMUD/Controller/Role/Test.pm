#!/usr/bin/env perl
package AberMUD::Controller::Role::Test;
use Moose::Role;
use namespace::autoclean;

override _mud_start => sub { };

override run => sub { };

override send => sub {
    my $self = shift;
    my ($id, $message) = @_;

    my $p = $self->universe->players->{$id};
#    if ($p->meta->name ne 'AberMUD::Test::Player') {
#        warn "not a test player";
#        return;
#    }

#    $p->
};

1;

