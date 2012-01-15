package AberMUD::Special::Hook::Command;
use Moose;
extends 'AberMUD::Special::Hook';

has command_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around call => sub {
    my ($orig, $self) = (shift, shift);
    my ($when, $universe, %args) = @_;
    return unless $self->command_name eq $args{name};

    return $self->$orig($when, %args);

};

no Moose;

1;
