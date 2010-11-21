#!/usr/bin/env perl
package AberMUD::Universe;
use Moose;
use namespace::autoclean;
extends 'MUD::Universe';
use Scalar::Util qw(weaken);
use KiokuDB;
use KiokuDB::Util qw(set);
use KiokuDB::Set;
use Set::Object::Weak;
use KiokuDB::Backend::DBI;
use List::MoreUtils qw(any);
use List::Util qw(first);
use Try::Tiny;
use AberMUD::Util;

with qw(
    AberMUD::Universe::Role::Mobile
    AberMUD::Universe::Role::Violent
);

has '+players' => (
    traits  => ['Hash', 'KiokuDB::DoNotSerialize'],
    handles => {player_list => 'values'}
);

has '+spawn_player_code' => (
    required => 0,
    traits   => ['KiokuDB::DoNotSerialize'],
);

has players_in_game => (
    is         => 'rw',
    isa        => 'HashRef[AberMUD::Player]',
    traits => ['Hash', 'KiokuDB::DoNotSerialize'],
    handles    => {
        game_name_list => 'keys',
        game_list      => 'values',
    },
);

has storage => (
    is => 'rw',
    isa => 'AberMUD::Storage',
    traits => ['KiokuDB::DoNotSerialize'],
);

has _controller => (
    is       => 'rw',
    isa      => 'MUD::Controller',
    handles  => {
        _get_input_state => 'get_input_state',
    },
    traits => ['KiokuDB::DoNotSerialize'],
);

has objects => (
    is      => 'rw',
    isa     => 'KiokuDB::Set',
    handles => {
        get_objects => 'members',
    },
    lazy    => 1,
    builder => '_build_objects',
);
sub _build_objects { set() }

has gateway_cache => (
    is      => 'rw',
    isa     => 'Set::Object::Weak',
    builder => '_build_gateway_cache',
    lazy    => 1,
    traits  => ['KiokuDB::DoNotSerialize'],
);

sub _build_gateway_cache {
    my $self = shift;

    my @objects = grep { $_->gateway } $self->get_objects;
    my $set = Set::Object::Weak->new(@objects);

    return $set;
}

has revealing_gateway_cache => (
    is      => 'rw',
    isa     => 'Set::Object::Weak',
    builder => '_build_revealing_gateway_cache',
    lazy    => 1,
    traits  => ['KiokuDB::DoNotSerialize'],
);

sub _build_revealing_gateway_cache {
    my $self = shift;

    my @objs = ();
    if ($self->gateway_cache) {
        @objs = grep { $_->openable ? $_->opened : 1 }
                $self->gateway_cache->members;
    }

    my $set = Set::Object::Weak->new(@objs);
    return $set;
}

has corpse_location => (
    is  => 'ro',
    isa => 'AberMUD::Location',
    builder => '_build_corpse_location',
    lazy => 1,
    #weak_ref => 1,
);

sub _build_corpse_location {
    my $self = shift;

    return AberMUD::Location->new(
        universe => $self,
        title => 'Dead Zone',
        description => q[This is the zone for corpses. ] .
                       q[Mortals do not belong here.],
    );
}

sub killables {
    my $self = shift;
    return ($self->game_list, $self->get_mobiles);
}

sub broadcast {
    my $self   = shift;
    my $output = shift;
    my %args = @_;
    $args{prompt} ||= 1;

    my @except;
    @except = (ref($args{except}) eq 'ARRAY')
            ? @{$args{except}}
            : (defined($args{except}) ? $args{except} : ());

            my %outputs;
    foreach my $player (values %{ $self->players_in_game }) {
        next if @except && any { $_ == $player } @except;
        my $player_output = $output;

        $player_output .= sprintf("\n%s", $player->final_prompt) if $args{prompt};
        $outputs{$player->id} = AberMUD::Util::colorify("\n$player_output");
    }

    $self->_controller->multisend(%outputs);
}

sub abermud_message {
    return unless $ENV{'ABERMUD_DEBUG'} && $ENV{'ABERMUD_DEBUG'} > 0;

    my $self = shift;
    my $msg = shift;

    print STDERR sprintf("\e[0;36m[ABERMUD]\e[m ${msg}\n", @_);
}

# Advance the universe through time
sub advance {
    my $self = shift;
}

sub identify {
    my $self     = shift;
    my ($location, $word) = @_;

    $self->identify_from_list(
        $location, $word, (
            $self->game_list,
            $self->get_mobiles,
            $self->get_objects,
        ),
    );
}

sub identify_object {
    my $self     = shift;
    my ($location, $word) = @_;

    $self->identify_from_list($location, $word, $self->get_objects);
}

sub identify_mobile {
    my $self     = shift;
    my ($location, $word) = @_;

    $self->identify_from_list($location, $word, $self->get_mobiles);
}

sub identify_from_list {
    my $self     = shift;
    my $location = shift;
    my $word     = lc shift;
    my @list     = @_;

    my ($offset) = ($word =~ s/(\d+)$//) || 1;

    my @subset = grep {
    $_->in($location) and $_->name_matches($word)
    } @list;

    my $index = $offset - 1;
    return $subset[$index] if $index <= @subset;
    return undef;
}

sub get_object_by_moniker {
    my $self    = shift;
    my $moniker = shift;

    my ($object) =
    grep {
        $_->moniker and $_->moniker eq $moniker
    } $self->get_objects;

    return $object;
}

sub check_exit {
    my $self = shift;
    my ($location, $direction) = @_;

    my $link_method = $direction . '_link';

    my $in_room = $location->objects_in_room->_objects;

    my $open_gateways = $self->revealing_gateway_cache *
                      $in_room;

    my $gateway = first {
        $_->$link_method and
        $_->in($location)
    } $open_gateways->members;

    if ($gateway and !$gateway->$link_method) {
        warn $location->title . " -> $direction not found" ;
        return undef;
    }

    return $gateway ? $gateway->$link_method->location : $location->$direction;
}

__PACKAGE__->meta->make_immutable;

1;
