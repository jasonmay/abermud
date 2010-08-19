#!/usr/bin/env perl
package AberMUD::Universe;
use Moose;
use namespace::autoclean;
extends 'MUD::Universe';
use Scalar::Util qw(weaken);
use KiokuDB;
use KiokuDB::Backend::DBI;
use List::MoreUtils qw(any);
use AberMUD::Util;

with qw(
    AberMUD::Universe::Role::Mobile
    AberMUD::Universe::Role::Violent
);

has '+players' => (
    traits  => ['Hash'],
    handles => {player_list => 'values'}
);

has players_in_game => (
    is         => 'rw',
    isa        => 'HashRef[AberMUD::Player]',
    traits     => ['Hash'],
    handles    => {
        game_name_list => 'keys',
        game_list      => 'values',
    },
    default    => sub { +{} },
);

has storage => (
    is => 'ro',
    isa => 'AberMUD::Storage',
    required => 1,
);

has _controller => (
    is       => 'ro',
    isa      => 'MUD::Controller',
    required => 1,
    handles  => {
        _get_input_state => 'get_input_state',
    },
);

has nowhere_location => (
    is => 'rw',
    isa => 'AberMUD::Location',
    default => sub {
        AberMUD::Location->new(
            id          => '__nowhere',
            world_id    => '__nowhere@void',
            title       => 'Nowhere',
            description => 'You are nowhere...',
        )
    }
);

has objects => (
    is  => 'rw',
    isa => 'ArrayRef[AberMUD::Object]',
    auto_deref => 1,
    default => sub { [] },
);

sub killables {
    my $self = shift;
    return ($self->players, $self->mobiles);
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
            $self->mobiles,
            $self->objects,
        ),
    );
}

sub identify_object {
    my $self     = shift;
    my ($location, $word) = @_;

    $self->identify_from_list($location, $word, $self->objects);
}

sub identify_mobile {
    my $self     = shift;
    my ($location, $word) = @_;

    $self->identify_from_list($location, $word, $self->mobiles);
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

sub objects_contained_by {
    my $self   = shift;
    my $object = shift;

    return () unless $object->container;

    return
        grep {
        $_->containable
            && $_->contained_by
            && $_->contained_by == $object
        } $self->objects;
}

sub display_container_contents {
    my $self      = shift;
    my $container = shift;

    return undef unless $container->container;

    return $self->_show_container_contents($container, 0);
}

sub _show_container_contents {
    my $self = shift;

    my ($object, $tabs) = @_;

    my $output = '';
    my $first_object = 1;
    my @contained_containers;
    my @contained = $self->objects_contained_by($object);

    #warn map { $_->name } @contained;
    foreach (@contained) {
        next unless $_->containable;
        next unless $_->contained_by($object);

        if ($first_object) {
            $output .= '    ' x $tabs;
        }
        else {
            $output .= ' ';
        }

        $output .= $_->name;

        push @contained_containers, $_ if $_->container;
    }

    foreach (@contained_containers) {
        if ($_->openable and !$_->opened) {
            $output .= sprintf(
                "\n%sThe %s is closed.",
                '    ' x $tabs, $_->name,
            );
        }
        elsif ($self->objects_contained_by($_)) {
            $output .= sprintf(
                "\n%sThe %s contains:\n%s",
                '    ' x $tabs, $_->name, $self->_show_container_contents($_, $tabs + 1),
            );
        }
    }

    return $output;
}

sub check_exit {
    my $self = shift;
    my ($location, $direction) = @_;

    my $link_method = $direction . '_link';
    my $door;
    foreach my $obj ($self->objects) {
        if (
            $obj->in($location)
                and $obj->gateway and $obj->$link_method
                and ($obj->openable ? $obj->opened : 1)
        ) {
            $door = $obj; last;
        }
    }

    $door ? $door->$link_method->location : $location->$direction;

}

__PACKAGE__->meta->make_immutable;

1;
