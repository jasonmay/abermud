#!/usr/bin/env perl
package AberMUD::Universe::Role::Mobile;
use Moose::Role;
use namespace::autoclean;

warn "hey";
has mobiles => (
    is  => 'rw',
    isa => 'ArrayRef[AberMUD::Mobile]',
    auto_deref => 1,
    default => sub { [] },
);

sub foobar {}

around advance => sub {
    my $orig = shift;
    my $self = shift;

    for my $mobile ($self->mobiles) {
        if ($self->roll_to_move($mobile)) {
            warn sprintf( "go %s go!", $mobile->name);
            $mobile->move;
            warn $mobile->location->world_id;
        }
    }
    return $self->$orig(@_);
};

sub roll_to_move {
    my $self = shift;
    my $mobile = shift;
    return 0 unless $mobile->speed; # don't move if speed is zero

    warn rand(30) . ' < ' . $mobile->speed;
    my $go = !!( rand(30) < $mobile->speed );
    return $go;
}

1;
