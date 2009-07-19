#!/usr/bin/env perl
package AberMUD::Input::Dispatcher::Rule;
use Moose;

extends 'Path::Dispatcher::Rule';

has string => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;

    return $path->path eq substr($self->string, 0, length($path->path))
        unless $self->prefix;

    my $truncated = substr($path->path, 0, length($self->string));
    return 0 unless $truncated eq substr($self->string, 0, length($truncated));

    return (1, substr($path->path, length($self->string)));
}

sub readable_attributes { q{"} . shift->string . q{"} }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

