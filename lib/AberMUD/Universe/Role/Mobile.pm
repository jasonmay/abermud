#!/usr/bin/env perl
package AberMUD::Universe::Role::Mobile;
use Moose::Role;
use namespace::autoclean;

has mobiles => (
    is  => 'rw',
    isa => 'ArrayRef[AberMUD::Mobile]',
    auto_deref => 1,
    default => sub { [] },
);

around advance => sub {
    my $orig = shift;
    my $self = shift;

    for my $mobile ($self->mobiles) {
        if ($self->roll_to_move($mobile)) {
            $mobile->move;
        }
    }
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
