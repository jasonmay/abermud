#!/usr/bin/env perl
package AberMUD::Role::Command;
use Moose::Role;

=head1 NAME

Foo -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

has priority => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);

has aliases => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

no Moose::Role;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

