#!/usr/bin/env perl
package AberMUD::Role::InGame;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Location;
use AberMUD::Location::Util qw(directions);
use List::MoreUtils qw(any);

has universe => (
    is       => 'rw',
    isa      => 'AberMUD::Universe',
    weak_ref => 1,
    traits   => ['KiokuDB::DoNotSerialize'],
);

has location => (
    is => 'rw',
    isa => 'AberMUD::Location',
    handles => {
        map {
            ("can_go_$_" => sub { $_ })
        } directions()
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
    $self->universe->game_list;

    $_->send("\n$message") for @players;

    return $self;
}

1;
