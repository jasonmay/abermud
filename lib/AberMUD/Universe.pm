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

has players_in_game => (
    is  => 'rw',
    isa => 'HashRef[AberMUD::Player]',
    default => sub { +{} },
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

has mobiles => (
    is  => 'rw',
    isa => 'ArrayRef[AberMUD::Mobile]',
    default => sub { [] },
);

has objects => (
    is  => 'rw',
    isa => 'ArrayRef[AberMUD::Object]',
    default => sub { [] },
);

sub broadcast {
    my $self   = shift;
    my $output = shift;
    my %args = @_;
    $args{prompt} ||= 1;

    my @except;
    @except = (ref($args{except}) eq 'ARRAY')
            ? @{$args{except}}
            : (defined($args{except}) ? $args{except} : ());

    foreach my $player (values %{$self->players_in_game}) {
        next if @except && any { $_ == $player } @except;
        my $player_output = $output;
        $player_output .= sprintf("\n%s", $player->prompt)
            if $args{prompt};
        $self->_controller->send(
            $player->id => AberMUD::Util::colorify("\n$player_output")
        );
    }
}

sub abermud_message {
    return unless $ENV{'ABERMUD_DEBUG'} && $ENV{'ABERMUD_DEBUG'} > 0;

    my $self = shift;
    my $msg = shift;

    print STDERR sprintf("\e[0;36m[ABERMUD]\e[m ${msg}\n", @_);
}

__PACKAGE__->meta->make_immutable;

1;
