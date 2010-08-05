package AberMUD::Input::Command;
use Scalar::Util qw(blessed);
use Moose;
use namespace::autoclean;
use Carp;

has priority => (
    is  => 'ro',
    isa => 'Int',
    default => 0,
);

has code => (
    is  => 'ro',
    isa => 'CodeRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

