#!/usr/bin/env perl
package AberMUD::Universe::Role::Mobile;
use Moose::Role;
use namespace::autoclean;

has mobiles => (
    is  => 'rw',
    isa => 'ArrayRef[AberMUD::Mobile]',
    traits => ['Array'],
    handles => {
        get_mobiles => 'elements',
    },
    default => sub { [] },
);

around advance => sub {
    my $orig = shift;
    my $self = shift;

    my @moving_mobiles = grep {
        $_->speed and $_->speed > 0
            and $self->roll_to_move($_)
    } $self->get_mobiles;

    warn "START";
    $_->move for @moving_mobiles;
    warn "END";

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
