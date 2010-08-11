package AberMUD::Web::Model::KiokuDB;
use Moose;
use namespace::autoclean;

use AberMUD::Storage;

BEGIN { extends 'Catalyst::Model::KiokuDB' };

has '+model_class' => ( default => "AberMUD::Storage" );

=head1 NAME

AberMUD::Web::Model::KiokuDB - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

