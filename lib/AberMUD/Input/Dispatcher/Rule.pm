#!/usr/bin/env perl
package AberMUD::Input::Dispatcher::Rule;
use Moose;
use namespace::autoclean;

extends 'Path::Dispatcher::Rule';

has command => (
    is      => 'rw',
    isa     => 'AberMUD::Input::Command',
);

sub _match {
    my $self = shift;
    my $path = shift;

    my $input = $path->path;
    return 0 unless length($input);
    if (defined $self->command->alias) {
        my $truncated_input = substr($input, 0, length($self->command->alias));
        if ($truncated_input eq $self->command->alias) {
            $input =~ s/^$truncated_input/$self->command->name.' '/e;
        }
    }

    my @words = split ' ', $input;
    my $entered_command = shift(@words);
    my $truncated = substr($self->command->name, 0, length($entered_command));

    my $leftover = join ' ' => @words;

    return 0 unless $truncated eq $entered_command;
    return (1, $leftover);
}

sub readable_attributes { q{"} . shift->command->name . q{"} }

__PACKAGE__->meta->make_immutable;

1;

