package AberMUD::Special::Hook::Sacrifice;
use Moose;
extends 'AberMUD::Special::Hook';

has object => (
    is       => 'ro',
    isa      => 'AberMUD::Object',
    required => 1,
);

around call => sub {
    my ($orig, $self) = (shift, shift);
    my ($when, %args) = @_;
    return unless $self->object eq $args{object};

    return $self->$orig($when, %args);

};

no Moose;

1;
