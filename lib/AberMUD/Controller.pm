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

use constant connection_class => 'AberMUD::Connection';

with qw(
    MooseX::Traits
);

has '+input_states' => (
    lazy    => 1,
    builder => '_build_input_states',
);

sub _build_input_states {
    my $self = shift;
    my %input_states;
    foreach my $input_state_class ($self->_input_states) {
        next unless $input_state_class;
        Class::MOP::load_class($input_state_class);
        my $input_state_object = $input_state_class->new(
            universe          => $self->universe,
            command_composite => $self->command_composite,
            special_composite => $self->special_composite,
        );

        $input_states{ $input_state_class } = $input_state_object;
    }

    return \%input_states;
}

has special_composite => (
    is  => 'ro',
    isa => 'AberMUD::Special',
);

has command_composite => (
    is       => 'ro',
    isa      => 'AberMUD::Input::Command::Composite',
    required => 1,
);

has storage => (
    is       => 'ro',
    isa      => 'AberMUD::Storage',
    required => 1,
    handles => [
        'save_player',
    ],
);

around build_response => sub {
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    my $conn = $self->connection($id);

    my $response = $self->$orig(@_);
    my $output;

    $output = "NULL!\n"
        unless $conn && @{$conn->input_states};

    my $player = $conn->associated_player;
    if (
        $player &&
        !$self->universe->player($player->name) &&
        ref $conn->input_state eq 'AberMUD::Input::State::Game'
    ) {
        $player = $self->materialize_player($conn, $player);
        my $prompt = $player->final_prompt;
        $output = "$response\n$prompt";
    }
    else {
        $output = $response;
    }

    # sweep here

    return AberMUD::Util::colorify($output);
};

around connect_hook => sub {
    my $orig   = shift;
    my $self   = shift;
    my ($data) = @_;

    my $result = $self->$orig(@_);

    return $result if $data->{param} ne 'connect';

    my $id = $data->{data}->{id};

    my $conn = $self->connection($id);

    return +{
        param => 'output',
        data => {
            id    => $id,
            value => $conn->input_state->entry_message,
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
    my $conn = $self->connection( $data->{data}{id} );
    if ($conn && $conn->has_associated_player) {
        my $player = $conn->associated_player;

        # XXX tell players leaving the game,
        # then mark to disconnect
        $player->disconnect;

        # XXX
        #$u->broadcast($player->name . " disconnected.\n")
        #    unless $data->{data}->{ghost};

        $conn->shift_state;

        delete $u->players_in_game->{$player->name};
    }

    my $result = $self->$orig(@_);

    return $result;
};

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

sub new_connection {
    my $self = shift;
    my @states = $self->storage->lookup_default_input_states();
    return AberMUD::Connection->new(
        input_states => [ @{$self->input_states}{@states} ],
        storage      => $self->storage,
    );
}

sub new_player {
    my $self   = shift;
    my %params = @_;

    my $player = AberMUD::Player->new(%params);

    # ...

    return $player;
}

sub materialize_player {
    my $self   = shift;
    my ($conn, $player) = @_;

    my $u = $self->universe;

    my $m_player = $conn->associated_player || $player;

    if ($m_player != $player && $m_player->in_game) {
        $self->ghost_player($m_player);
        return $self;
    }

    # XXX I'm sure we need this, just don't feel like
    # making this work right now
    #if (!$m_player->in_game) {
    #    $self->copy_unserializable_player_data($m_player, $player);
    #    $u->players->{$player->name} = $player;
    #}

    # XXX
    #$m_player->_join_game;
    # $self->save_player($m_player) if $m_player == $player;
    $m_player->setup;

    return $m_player;
}

sub dematerialize_player {
    my $self   = shift;
    my $player = shift;
    delete $self->universe->players_in_game->{lc $player->name};
}

sub copy_unserializable_player_data {
    my $self = shift;
    my $source_player = shift;
    my $dest_player = shift;

    for ($source_player->meta->get_all_attributes) {
        if ($_->does('KiokuDB::DoNotSerialize')) {
            my $attr = $_->accessor;
            next if $attr eq 'dir_player';
            $dest_player->$attr($source_player->$attr)
                if defined $source_player->$attr;
        }
    }
}

sub ghost_player {
    my $self   = shift;
    my $new_player = shift;
    my $old_player = shift;
    my $u = $self->universe;

    return unless $old_player->id and $new_player->id;

    $self->force_disconnect($old_player->id, ghost => 1);
    $u->players->{$new_player->id} = delete $u->players->{$old_player->id};
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
