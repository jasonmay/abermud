#!/usr/bin/env perl
package AberMUD::Universe;
use Moose;

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
use Data::UUID::LibUUID;
use AberMUD::Location::Util qw(show_exits);

has players => (
    is      => 'ro',
    isa     => 'HashRef[AberMUD::Player]',
    traits  => ['Hash', 'KiokuDB::DoNotSerialize'],
    default => sub { {} },
    handles => {
        player_list => 'values',
        player      => 'get',
    }
);

with qw(
    AberMUD::Universe::Role::Mobile
    AberMUD::Universe::Role::Violent
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
    is        => 'ro',
    isa       => 'AberMUD::Location',
    builder   => '_build_corpse_location',
    lazy      => 1,
    #weak_ref => 1,
);

sub _build_corpse_location {
    my $self = shift;

    return AberMUD::Location->new(
        universe    => $self,
        title       => 'Dead Zone',
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

    foreach my $player ($self->player_list) {
        next if @except && any { $_ == $player } @except;
        my $player_output = $output;

        $player_output .= sprintf("\n%s", $player->final_prompt) if $args{prompt};
        $player->append_output_buffer(
            AberMUD::Util::colorify("\n$player_output")
        );
    }

}

sub send_to_location {
    my $self    = shift;
    my $ingame  = shift;
    my $message = shift;
    my %args    = @_;

   my @except = ref($args{except}) eq 'ARRAY'
                    ? (@{$args{except} || []})
                    : ($args{except} || ());

    my @players = grep {
        my $p = $_;
        $p->location == $ingame->location && !any { $p == $_ } @except
    } $self->player_list;

    $_->append_output_buffer("\n$message") for @players;

    return $self;
}


# should be thrown into a logger object?
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

sub look {
    my $self   = shift;
    my $loc    = shift;

    my $output = '';
    #my $output .= sprintf(
    #    "&+M%s&* &+B[&+C%s@%s&+B]&*\n",
    #    $loc->title,
    #    lc substr($self->universe->storage->object_to_id($loc), 0, 8),
    #    $loc->zone->name,
    #);

    $output .= $loc->description;
    chomp $output; $output .= "\n";

    foreach my $object ($self->get_objects) {
        next unless $object->location;
        next unless $object->location == $loc;
        next unless $object->on_the_ground;

        my $desc = $object->final_description;
        next unless $desc;

        $output .= "$desc\n";
    }

    foreach my $mobile ($self->get_mobiles) {
        next unless $mobile->location;
        my $desc = $mobile->description;
        $desc .= sprintf q( [%s/%s]), $mobile->current_strength, $mobile->max_strength;
        $desc .= sprintf q( [agg: %s]), $mobile->aggression;

        if ($mobile->location == $loc) {
            $output .= "$desc\n";
            my $inv = $mobile->show_inventory;
            $output .= "$inv\n" if $inv;
        }
    }

    foreach my $player (values %{$self->players}) {
        next if $player == $self;
        $output .= ucfirst($player->name) . " is standing here.\n"
            if $player->location == $self->location;
    }

    $output .= "\n" . show_exits(location => $loc, universe => $self);

    return $output;
}

sub clone_object {
    my $self = shift;
    my ($object, %extra_params) = @_;


    my $new_object = $object->meta->clone_object(
        $object,
        id => new_uuid_string(),
        %extra_params,
    );

    if ($object->getable) {
        $new_object->_stop_being_held;
        $new_object->_stop_being_contained;
        $new_object->dropped(1);
    }

    $self->objects->insert($new_object);

    # TODO insert into caches if applicable?

    return $new_object;
}

sub can_move {
    my $self = shift;
    my ($ingame, $direction) = @_;
    return 0 unless $ingame->location;

    return $self->check_exit(
        $ingame->location,
        $direction,
    );
}

sub move {
    my $self = shift;
    my ($ingame, $direction, %args) = @_;

    my $destination = $self->can_move($ingame, $direction)
        or return undef;

    $self->send_to_location(
        $ingame,
        sprintf("\n%s goes %s\n", $ingame->name, $direction),
        except => $ingame,
    ) if $args{announce};

    $ingame->change_location($destination);

    my %opp_dir = (
        east  => 'the west',
        west  => 'the east',
        north => 'the south',
        south => 'the north',
        up    => 'below',
        down  => 'above',
    );

    $self->send_to_location(
        $ingame,
        sprintf(
            "\n%s arrives from %s\n",
            $ingame->name, $opp_dir{$direction}
        ),
        except => $ingame,
    ) if $args{announce};

    return $destination;
}

__PACKAGE__->meta->make_immutable;

1;
