#!/usr/bin/env perl
package AberMUD::Universe;
use Moose;
extends 'MUD::Universe';
use Scalar::Util qw(weaken);
use KiokuDB;
use KiokuDB::Backend::DBI;

has directory => (
    is  => 'rw',
    isa => 'KiokuDB',
    default => sub {
        KiokuDB->connect('dbi:SQLite:dbname=abermud', create => 1)
    },
);

has directory_scope => (
    is  => 'rw',
    isa => 'KiokuDB::LiveObjects::Scope',
);

has players_in_game => (
    is  => 'rw',
    isa => 'HashRef[AberMUD::Player]',
    default => sub { +{} },
);

sub BUILD {
    my $self = shift;
    $self->directory_scope($self->directory->new_scope);
}

sub load_player {
    my $self = shift;
    my $player = shift;
    my %args = @_;
}

sub broadcast {
    my $self   = shift;
    my $output = shift;

    foreach my $player (values %{$self->players_in_game}) {
        $player->io->put($output);
    }
}

sub abermud_message {
    return unless $ENV{'ABERMUD_DEBUG'} > 0;
    my $self = shift;
    my $msg = shift;
    print STDERR sprintf("\e[0;36m[ABERMUD]\e[m ${msg}\n", @_);
}

sub player_lookup {
    my $self = shift;
    my $name = shift;
    return $self->directory->lookup("player-$name");
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
