#!/usr/bin/env perl
package AberMUD::Controller;
use Moose;
#use MooseX::POE;
extends 'MUD::Controller';
use AberMUD::Player;
use AberMUD::Mobile;
use AberMUD::Universe;
use AberMUD::Util;
use JSON;
use Data::UUID::LibUUID;
use DDS;

use Module::Pluggable
    search_path => ['AberMUD::Input::State'],
    sub_name    => '_input_states',
;

#use namespace::autoclean;

with qw(
    MooseX::Traits
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
        $player = $player->materialize;
        my $prompt = $player->final_prompt;
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
    return +{
        param => 'output',
        data => {
            id    => $id,
            value => $self->universe->players->{$id}->input_state->[0]->entry_message,
        },
        txn_id => new_uuid_string(),
    }
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
    my $player = $self->universe->players->{ $data->{data}{id} };
    if ($player && exists $u->players_in_game->{$player->name}) {
        $player->disconnect;
        $player->dematerialize;

        $u->broadcast($player->name . " disconnected.\n")
            unless $data->{data}->{ghost};

        $player->shift_state;
    }

    delete $u->players_in_game->{$player->name};
    my $result = $self->$orig(@_);

    return $result;
};

sub _load_input_states {
    my $self = shift;

    foreach my $input_state_class ($self->_input_states) {
        next unless $input_state_class;
        Class::MOP::load_class($input_state_class);
        my $input_state_object = $input_state_class->new(
            universe => $self->universe,
        );
        $self->set_input_state($input_state_class => $input_state_object);
    }
}

sub BUILD {
    my $self = shift;

    $self->_load_input_states;
}

{
    # AberMUDs have a tick every two seconds
    my $two_second_toggle = 0;
    around tick => sub {
        my $orig = shift;
        my $self = shift;

        if ($two_second_toggle) {
            $self->universe->can('advance')
                && $self->universe->advance;
        }
        $two_second_toggle = !$two_second_toggle;
    };
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
