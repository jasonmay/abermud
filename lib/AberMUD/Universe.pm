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
    handles    => {game_list => 'values'},
    default    => sub { +{} },
);

has directory => (
    is => 'ro',
    isa => 'AberMUD::Directory',
    required => 1,
);

has _controller => (
    is => 'ro',
    isa => 'MUD::Controller',
    required => 1,
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

# identify everything
sub identify {
    my $self     = shift;
    my $location = shift;
    my $word     = lc shift;

    my ($offset) = ($word =~ s/(\d+)$//) || 1;
    my @list;


    @list =
    grep {
    (
        ($_->can('name')         && lc($_->name)         eq $word) ||
        ($_->can('display_name') && lc($_->display_name) eq $word) ||
        ($_->can('alt_name')     && lc($_->alt_name)     eq $word)
    )
    && $_->can('location') && $_->location
    && $_->location == $location
    } ($self->game_list, $self->mobiles, $self->objects);

    warn "@list";
    my $index = $offset - 1;
    return $list[$index] if $index <= @list;
    return undef;
}

__PACKAGE__->meta->make_immutable;

1;
