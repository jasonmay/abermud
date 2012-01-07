package AberMUD::Special::Hook::Death;
use Moose;
extends 'AberMUD::Special::Hook';

has victim => (
    is       => 'ro',
    isa      => 'AberMUD::Killable',
    required => 1,
);

around call => sub {
    my ($orig, $self) = (shift, shift);
    my ($when, %args) = @_;
    return unless $self->victim eq $args{victim};

    return $self->$orig($when, %args);

};

no Moose;

1;
