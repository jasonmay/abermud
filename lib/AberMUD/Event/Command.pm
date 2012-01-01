package AberMUD::Event::Command;
use Moose;

has universe => (
    is  => 'ro',
    isa => 'AberMUD::Universe',
);

has player => (
    is  => 'ro',
    isa => 'AberMUD::Player',
);

has arguments => (
    is  => 'ro',
    isa => 'Str',
);

no Moose;

1;
