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

sub BUILD {
    my $self = shift;
    $self->scope;
}

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

sub build_universe {
    my $self = shift;
    my %args = @_;

    my ($config, $locations) = ($args{config}, $args{locations});

    $self->txn_do(
        sub {
            my $backend = $self->directory->backend;
            if (
                blessed($backend->storage) &&
                $backend->storage->isa('DBIx::Class::Storage::DBI')
            ) {
                $backend->dbh_do(
                    sub {
                        my ($storage, $dbh) = @_;
                        if ($storage->isa('DBIx::Class::Storage::DBI::Pg')) {
                            $dbh->do('truncate entries cascade');
                        }
                        else {
                            $dbh->do("delete from $_") for qw/gin_index entries/;
                        }
                    }
                );
            }

            $self->store($locations);
            $self->store(config => $config);

            # assign IDs to locations and update
            my @with_ids = map { ($_->members) } $locations,
                                                 $config->universe->objects,
                                                 $config->universe->mobiles;

            $_->id($self->object_to_id($_)) for @with_ids;
            $self->update(@with_ids);

            # set root to everything we stored
            my @all_objects = $self->scope->live_objects->live_objects;
            $self->set_root(@all_objects);
            $self->update(@all_objects);
        }
    );
}

sub save_player {
    my $self = shift;
    my $player = shift;
    my %args = @_;

    # XXX
    #if (!$player->in_game) {
    #    return;
    #}

    if ($self->player_lookup($player->name)) {
        $self->update($player);
    }
    else {
        $self->store('player-'.lc($player->name) => $player);
    }
}

sub load_player_data {
    my $self   = shift;
    my $player = shift;

    if ($player->is_saved) {
        my $stored_player
            = $self->lookup('player-' . lc $player->name);
        for ($stored_player->meta->get_all_attributes) {
            if ($_->does('KiokuDB::DoNotSerialize')) {
                my $attr = $_->accessor;
                $stored_player->$attr($self->$attr)
            }
        }
        # XXX
        #$u->players->{$self->id} = $stored_player;
        return $stored_player;
    }

    return $player;
}

sub lookup_default_input_states {
    my $self   = shift;
    my $config = $self->lookup('config');
    my @states = @{ $config->input_states };
    return map { "AberMUD::Input::State::$_" } @states;
}

sub lookup_default_location {
    my $self   = shift;
    my $config = $self->lookup('config');
    return $config->location;
}

sub lookup_universe {
    my $self   = shift;
    my $config = $self->lookup('config');
    return $config->universe;
}

__PACKAGE__->meta->make_immutable;

1;

