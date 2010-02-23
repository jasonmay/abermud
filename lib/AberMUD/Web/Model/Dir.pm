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

sub get_loc {
    my $self = shift;
    my $world_id = shift;
    my $scope = $self->new_scope;
    $self->lookup("location-$world_id");
}

sub gen_world_id {
    my $self = shift;
    my $zone = shift;
    my $scope = $self->new_scope;
    my $s = $self->grep(
        sub {
            $_->isa('AberMUD::Location')
            and $_->zone == $zone
        }
    );

    my @id_nums;
    while (my $block = $s->next) {
        for (@$block) {
            my $z = $zone->name;
            push @id_nums, ($_->world_id =~ /^$z(\d+)/);
            warn "@id_nums";
        }
    }

    my $new_num = max(@id_nums) + 1;
    return $zone->name . $new_num;
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

