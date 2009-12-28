#!/usr/bin/env perl
package AberMUD::Mobile;
use Moose;
use namespace::autoclean;

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

sub move {
    my $self = shift;
    return unless $self->location;

    my $loc  = $self->location;
    my @dirs = grep { $self->${\"can_go_$_"} } @{$self->location->directions};

    my $way = $dirs[rand @dirs];
    my %opp_dir = (
        east  => 'west',
        west  => 'east',
        north => 'south',
        south => 'north',
        up    => 'down',
        down  => 'up',
    );

    my $opp = $opp_dir{$way};

    $self->say($self->name . " goes $way.\n");
    $self->location($self->location->$way);
    $self->say($self->name . " arrives from the $opp.\n");
}

__PACKAGE__->meta->make_immutable;

1;

