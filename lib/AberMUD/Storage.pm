#!/usr/bin/env perl
package AberMUD::Storage;
use Moose;
use KiokuDB;
use KiokuDB::LiveObjects::Scope;
use YAML::XS qw(LoadFile);
use Scalar::Util qw(weaken);
use namespace::autoclean;

extends 'KiokuX::Model';

my $config = LoadFile('etc/db.yml');

has '+dsn' => ( default => delete($config->{dsn}) );

has '+extra_args' => (
    default => sub { $config },
);

has scope => (
    is      => 'rw',
    isa     => 'KiokuDB::LiveObjects::Scope',
    lazy_build => 1,
);

sub player_lookup {
    my $self = shift;
    my $name = shift;
    return $self->lookup("player-$name");
}

sub _build_scope {
    my $self = shift;
    $self->new_scope;
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

sub BUILD {
    my $self = shift;
    $self->scope; # can't make it eager. things break(?)
}

__PACKAGE__->meta->make_immutable;

1;

