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
use AberMUD::Location::Util qw(show_exits directions);

has players => (
    is      => 'ro',
    isa     => 'HashRef[AberMUD::Player]',
    traits  => ['Hash', 'KiokuDB::DoNotSerialize'],
    lazy    => 1,
    default => sub { {} },
    handles => {
        player_names => 'keys',
        player_list  => 'values',
        player       => 'get',
    }
);

with qw(
    AberMUD::Universe::Role::Mobile
    AberMUD::Universe::Role::Violent
    AberMUD::Universe::Role::WithSystemData
);

has locations => (
    is      => 'rw',
    isa     => 'KiokuDB::Set',
    lazy    => 1,
    builder => '_build_locations',
);
sub _build_locations { set() }

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

has special => (
    is     => 'ro',
    isa    => 'AberMUD::Special',
    traits => ['KiokuDB::DoNotSerialize'],
);

has connpleted_quests => (
    is     => 'ro',
    isa    => 'HashRef',
    traits => ['KiokuDB::DoNotSerialize'],
);

sub money_unit        { 'coin'  }
sub money_unit_plural { 'coins' }

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
        $player->append_output_buffer("\n$player_output");
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

    my @players;
    for my $player ($self->player_list) {
        next unless $player->location == $ingame->location;
        next if     any { $player == $_ } @except;
        push @players, $player;
    }

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
            $self->player_list,
            $self->get_mobiles,
            $self->get_objects,
        ),
    );
}

sub identify_object {
    my $self     = shift;
    my ($location, $word) = @_;

    my @objects = grep { defined() } $location->objects_in_room->members;
    $self->identify_from_list($location, $word, @objects);
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
    my %args   = @_;

    my $output = '';
    $output .= sprintf(
        "&+M%s&* &+B[&+C%s@%s&+B]&*\n",
        $loc->title,
        $loc->id,
        $loc->zone->name,
    );

    $output .= $loc->description;
    chomp $output; $output .= "\n";

    foreach my $object ($loc->objects_in_room->members) {
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
        next if exists($args{except}) && $player == $args{except};
        $output .= ucfirst($player->name) . " is standing here.\n"
            if $player->location == $loc;
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

    $new_object->location->objects_in_room->insert($new_object)
        if $new_object->location;

    if ($new_object->getable and $new_object->held_by) {
        $new_object->held_by->_carrying->insert($new_object);
    }
    if ($new_object->contained_by) {
        $new_object->contained_by->contents->insert($new_object);
    }

    $self->objects->insert($new_object);

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

    if ($ingame->isa('AberMUD::Mobile')) {
        return undef
            if $ingame->can('fighting') and $ingame->fighting;
    }

    $self->send_to_location(
        $ingame,
        sprintf("\n%s goes %s\n", $ingame->name, $direction),
        except => $ingame,
    ) if $args{announce};

    $self->change_location($ingame, $destination);

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

sub detach_things {
    my $self = shift;
    my ($player) = @_;

    my @objects = ($player->carrying);
    for my $object (@objects) {
        $object->_stop_being_held;
        $object->worn(0) if $object->wearable;
        $object->wielded(0) if $object->wieldable;
        $self->change_location($object, $player->location);
    }

}

# In case we need to do any universe-level caching
sub change_location {
    my $self = shift;
    my ($ingame, $location, %args) = @_;

    my $previous_location = $ingame->location;

    if ($ingame->isa('AberMUD::Player')) {
        my ($interrupt, @results) = $self->special->call_hooks(
            type => 'change_location',
            when => 'before',
            universe  => $self,
            arguments => [
                src => $previous_location,
                dest => $location,
            ],
        );

        $ingame->append_output_buffer("$_\n") for @results;

        # short-circult if we are told to interrupt
        return if $interrupt;
    }

    $ingame->change_location($location);

    if ($ingame->isa('AberMUD::Player')) {
        (undef, my @results) = $self->special->call_hooks(
            type      => 'change_location',
            when      => 'after',
            universe  => $self,
            arguments => [
                src => $previous_location,
                dest => $location,
            ],
        );

        $ingame->append_output_buffer("$_\n") for @results;
    }
}

sub complete_quest {
    my $self  = shift;
    my ($player, $quest) = @_;

    my $exp_award = 3000;

    # TODO $player->mark() and display the congrats
    # after we've processed everything
    my $output = "Congratulations! You've completed the &+C$quest&* quest!\n";

    if (!$player->completed_quests->{$quest}) {
        $output .=
            q[Since this is your first time completing it, you have been ] .
            qq[awarded &+Y$exp_award&* experience points!\n];

        $self->change_score($player, $exp_award);
    };

    $player->append_output_buffer($output);
    $player->completed_quests->{$quest}++;
    $player->mark(save => 1);
}

sub open {
    my $self = shift;
    my ($object) = @_;
    $self->_set_opened($object, 1);
}

sub close {
    my $self = shift;
    my ($object) = @_;
    $self->_set_opened($object, 0);
}

sub carry {
    my $self = shift;
    my ($killable, $object) = @_;
    $killable->_carrying->insert($object);
    $self->change_location($object, $killable->location)
        if $killable;
    $object->held_by($killable);
}

sub _set_opened {
    my $self = shift;
    my ($object, $open, $only_this_object) = @_;

    $object->opened($open);

    if ($object->gateway and !$only_this_object) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $object->$link_method;
            next unless $object->$link_method->openable;
            $self->_set_opened($object->$link_method, $open, 1);
        }
    }

    if ($object->gateway) {
        if ($open) {
            $self->revealing_gateway_cache->insert($object)
        }
        else {
            $self->revealing_gateway_cache->remove($object)
        }
    }
}

sub set_state {
    my $self      = shift;
    my $object    = shift;
    my $state     = shift;
    my $last_call = shift || 0; # base case to prevent loops

    if ($state == 0) {
        $self->revealing_gateway_cache->delete($object);
    }
    else {
        $self->revealing_gateway_cache->insert($object);
    }

    $object->state($state);

    if ($object->gateway and !$last_call) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $object->$link_method;
            next unless $object->$link_method->multistate;
            $self->set_state($object->$link_method, $state, 1);
        }
    }
}

sub change_score {
    my $self = shift;
    my ($player, $delta) = @_;

    my $prev_level = $player->level;

    $player->score($player->score + $delta);

    if ($player->level > $prev_level) {

        if ($player->level > $player->max_level) {
            for ($prev_level + 1 .. $player->level) {
                $self->broadcast(
                    sprintf(
                        "Congratulations to %s for making it to level &+C$_&*.\n",
                        $player->name
                    ),
                    except => $player,
                );

                $player->append_output_buffer("Congratulations! You made it to level &+C$_&*.\n"),
            }
            $player->max_level($player->level);
        }
    }
    elsif ($player->level < $prev_level) {
        $player->sendf(
            "You are back to level &+C%s&*.\n",
            $player->level,
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;
