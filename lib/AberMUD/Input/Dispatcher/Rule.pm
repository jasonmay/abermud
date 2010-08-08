#!/usr/bin/env perl
package AberMUD::Input::Dispatcher::Rule;
use Moose;
use namespace::autoclean;

extends 'Path::Dispatcher::Rule';

with 'AberMUD::Role::Command';

has command_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;

    my $input = $path->path;
    return 0 unless length($input);
    foreach my $alias (@{$self->aliases}) {
        my $truncated_input = substr($input, 0, length($alias));

        my $len = length($truncated_input);

        if ($truncated_input eq $self->alias) {
            $input = $self->name . ' '
                . substr($self->command_name, 0, $len);
        }
    }

    my @words = split ' ', $input;
    my $entered_command = shift(@words);
    my $truncated = substr($self->name, 0, length($entered_command));

    my $leftover = join ' ' => @words;

    return 0 unless $truncated eq $entered_command;
    return (1, $leftover);
}

sub readable_attributes { q{"} . shift->command_name . q{"} }

__PACKAGE__->meta->make_immutable;

1;

