#!/usr/bin/env perl
package AberMUD::Mobile;
use Moose;
use namespace::autoclean;

use AberMUD::Location::Util qw(directions);

with qw(
    AberMUD::Role::Killable
    AberMUD::Role::InGame
);

has id => (
    is  => 'rw',
    isa => 'Str',
);

has name => (
    is  => 'rw',
    isa => 'Str',
);

has display_name => (
    is  => 'rw',
    isa => 'Str',
);

has speed => (
    is  => 'rw',
    isa => 'Str',
);

has intrinsics => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

has spells => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { +{} },
);

has _held_objects => (
    is  => 'ro',
    isa => 'Kioku::Set',
);

sub move {
    my $self = shift;
    return unless $self->location;

    my $loc  = $self->location;
    my @dirs = grep { $self->${\"can_go_$_"} } directions();

    return $self unless @dirs;

    my $way = $dirs[rand @dirs];
    my %opp_dir = (
        east  => 'the west',
        west  => 'the east',
        north => 'the south',
        south => 'the north',
        up    => 'below',
        down  => 'above',
    );

    my $opp = $opp_dir{$way};

    $self->say($self->name . " goes $way.\n");
    $self->location($self->location->$way);
    $self->say($self->name . " arrives from $opp.\n");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

