package AberMUD::Web::Model::Dir;
use Moose;
use namespace::autoclean;

use AberMUD::Location;

extends 'Catalyst::Model::KiokuDB';

has _scope => (
    is  => 'rw',
    isa => 'KiokuDB::LiveObjects::Scope',
);

sub ACCEPT_CONTEXT {
    my $self = shift;
    my $c    = shift;

    return $self;
}

sub BUILD {
    my $self = shift;
    $self->_scope($self->new_scope);
}

__PACKAGE__->config(dsn => 'dbi:SQLite:dbname=abermud');

=head1 NAME

AberMUD::Web::Model::Dir - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

