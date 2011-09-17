#!/usr/bin/env perl
package AberMUD::Role::InGame;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Location;
use AberMUD::Location::Util qw(directions);
use List::MoreUtils qw(any);

has name => (
    is  => 'rw',
    isa => 'Str',
);

has location => (
    is  => 'rw',
    isa => 'AberMUD::Location',
);

has zone => (
    is  => 'rw',
    isa => 'AberMUD::Zone',
);

has description => (
    is  => 'rw',
    isa => 'Str',
);

has examine_description => (
    is  => 'rw',
    isa => 'Str',
);

sub local_to {
    my $self    = shift;
    my $in_game = shift;

    return 0 unless $in_game->can('location');
    return 0 unless $in_game->location;

    return $self->in($in_game->location);
}

sub in {
    my $self     = shift;
    my $location = shift;

    return ($self->location && $self->location == $location);
}

sub name_matches {
    my $self = shift;
    my $word = shift or return 0;

    return 1 if $self->name and lc($self->name) eq lc($word);

    return 0;
};

# separate layer for cache updates, etc.
sub change_location {
    my $self     = shift;
    my $location = shift;

    $self->location($location);
}

1;
