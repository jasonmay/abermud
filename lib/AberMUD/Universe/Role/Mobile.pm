#!/usr/bin/env perl
package AberMUD::Universe::Role::Mobile;
use Moose::Role;
use KiokuDB::Set;
use KiokuDB::Util qw(set);
use Time::HiRes ();
use namespace::autoclean;

has mobiles => (
    is  => 'rw',
    isa => 'KiokuDB::Set',
    handles => {
        get_mobiles => 'members',
    },
    default => sub { set() },
);

has traversable_mobiles => (
    is  => 'rw',
    isa => 'KiokuDB::Set',
    builder => '_build_traversable_mobiles',
    lazy    => 1,
    handles => {
        get_traversable_mobiles => 'members',
    },
);

sub _build_traversable_mobiles {
    my $self = shift;

    return set( grep { $_->speed and $_->speed > 0 } $self->get_mobiles );
}

around advance => sub {
    my $orig = shift;
    my $self = shift;

    my @moving_mobiles = grep {
        $self->roll_to_move($_)
    } $self->get_traversable_mobiles;

    warn "START: " . Time::HiRes::gettimeofday;
    $_->move for @moving_mobiles;
    warn "END: " . Time::HiRes::gettimeofday;

    return $self->$orig(@_);
};

sub roll_to_move {
    my $self = shift;
    my $mobile = shift;
    return 0 unless $mobile->speed; # don't move if speed is zero

    my $go = !!( rand(30) < $mobile->speed );
    return $go;
}

1;
