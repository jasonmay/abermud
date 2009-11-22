#!/usr/bin/env perl
package AberMUD::Universe;
use Moose;
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
    is => 'rw',
    isa => 'AberMUD::Directory',
    required => 1,
);

has nowhere_location => (
    is => 'rw',
    isa => 'AberMUD::Location',
    required => 1,
);

sub spawn_player {
    my $self     = shift;
    my $id       = shift;

    return AberMUD::Player->new(
        id => $id,
        prompt      => "&+Y\$&* ",
        universe    => $self,
        directory   => $self->directory,
        input_state => [
            map {
                Class::MOP::load_class($_);
                $_->new(
                    universe => $self,
                )
            }
            qw(
                AberMUD::Input::State::Login::Name
                AberMUD::Input::State::Game
            )
        ],
    );
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

    foreach my $player (values %{$self->players_in_game}) {
        next if @except && any { $_ == $player } @except;
        my $player_output = $output;
        $player_output .= sprintf("\n%s", $player->prompt)
            if $args{prompt};
        $player->io->put(AberMUD::Util::colorify("\n$player_output"));
    }
}

sub abermud_message {
    return unless $ENV{'ABERMUD_DEBUG'} && $ENV{'ABERMUD_DEBUG'} > 0;

    my $self = shift;
    my $msg = shift;

    print STDERR sprintf("\e[0;36m[ABERMUD]\e[m ${msg}\n", @_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
