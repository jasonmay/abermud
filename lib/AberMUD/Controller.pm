#!/usr/bin/env perl
package AberMUD::Controller;
use Moose;
#use MooseX::POE;
use namespace::autoclean;
extends 'MUD::Controller';
use AberMUD::Player;
use AberMUD::Universe;
use AberMUD::Util;
use POE::Session;
use POE::Kernel;
use JSON;
use DDS;

with qw(
    MooseX::Traits
);

has player_data_path => (
    is  => 'rw',
    isa => 'Str',
    default => "$ENV{PWD}/data"
);

around build_response => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;
    my $player = $self->universe->players->{$id};

    my $response = $self->$orig($id, @_);
    my $output;

    $output = "You are in a void of nothingness...\n"
        unless $player && @{$player->input_state};

    if ($player && ref $player->input_state->[0] eq 'AberMUD::Input::State::Game') {
        $player->materialize;
        my $prompt = $player->prompt;
        $output = "$response\n$prompt";
    }
    else {
        $output = $response;
    }

    return AberMUD::Util::colorify($output);
};

around connect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $result = $self->$orig(@_);

    return $result if $data->{param} ne 'connect';

    my $id = $data->{data}->{id};
    return to_json(
        {
            param => 'output',
            data => {
                id    => $id,
                value => $self->universe->players->{$id}->input_state->[0]->entry_message,
            }
        }
    );

};

before input_hook => sub {
    my $self = shift;
    my ($data) = @_;
};

around disconnect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $u = $self->universe;
    my $player = $self->universe->players->{ $data->{data}->{id} };
    if ($player && exists $u->players_in_game->{$player->name}) {
        $player->disconnect;
        $player->dematerialize;

        $u->broadcast($player->name . " disconnected.\n")
            unless $data->{data}->{ghost};

        $player->shift_state;
    }

    my $result = $self->$orig(@_);

    return $result;
};

sub _load_objects {
    my $self = shift;
    my $k = $self->universe->directory->kdb;

    my $universe_sets = $k->lookup('universe-sets');
    return unless $universe_sets;

    $self->universe->objects([values %{ $universe_sets->all_objects }]);
}

sub BUILD {
    my $self = shift;
    $self->_load_objects;
}

sub tick {
    my $self = shift;
    $_->move for $self->universe->mobiles;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

AberMUD::Controller - Logic that coordinates gameplay and I/O

=head1 SYNOPSIS

  my $abermud = AberMUD::Controller->new(universe => $universe);

=head1 DESCRIPTION

This module is basically L<MUD::Controller> with some modifications
involving player actions and POE-related enhancements.

See L<MUD::Controller> documentation for more details on the functionality
of this module.

=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

You may use this code under the same terms of Perl itself.
