#!/usr/bin/env perl
package AberMUD::Input::Command;
use Scalar::Util qw(blessed);
use Moose;
use namespace::autoclean;
use Carp;

has name => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_build_name',
);

sub _build_name {
    my $self = shift;
    my $command_name = blessed $self;
    $command_name =~ s/.+:://; $command_name =~ s/\.pm//;

    return lc($command_name);
}

has alias => (
    is  => 'rw',
    isa => 'Str',
);

sub sort { 0 }

sub run {
    croak "Please override the 'run' method.";
}

__PACKAGE__->meta->make_immutable;

1;

