#!/usr/bin/env perl
package AberMUD::Role::InGame;
use Moose::Role;

use AberMUD::Location;
use List::MoreUtils qw(any);

has universe => (
    is => 'rw',
    isa => 'AberMUD::Universe',
    traits => ['KiokuDB::DoNotSerialize'],
);

has location => (
    is => 'rw',
    isa => 'AberMUD::Location',
    traits => ['KiokuDB::DoNotSerialize'],
    handles => {
        map {
            ("can_go_$_" => "has_$_")
        } @{AberMUD::Location->directions}
    },
);

has description => (
    is  => 'rw',
    isa => 'Str',
);

has examine_description => (
    is  => 'rw',
    isa => 'Str',
);

sub say {
    my $self    = shift;
    my $message = shift;
    my %args    = @_;

   my @except = ref($args{except}) eq 'ARRAY'
                    ? (@{$args{except} || []})
                    : ($args{except} || ());

    my @players = grep {
        my $p = $_;
        $p->location == $self->location && !any { $p == $_ } @except
    }
    values %{$self->universe->players_in_game};

    $_->send($message) for @players;

    return $self;
}

no Moose::Role;

1;
