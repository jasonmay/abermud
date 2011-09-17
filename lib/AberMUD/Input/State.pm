#!/usr/bin/env perl
package AberMUD::Input::State;
use Moose::Role;

use AberMUD::Util ();

has universe => (
    is       => 'rw',
    isa      => 'AberMUD::Universe',
);

has entry_message => (
    is => 'rw',
    isa => 'Str',
);

requires 'run';

around run => sub {
    my ($orig, $self) = (shift, shift);
    my ($backend, $conn) = @_;

    my $response = $self->$orig(@_);

    my $player = $conn->associated_player;

    my $in_game = 0;
    $in_game = 1 if $player
        and $self->universe->player($player)
        and ref($conn->input_state) eq 'AberMUD::Input::State::Game';

    my $output;
    if ($in_game) {
        $player    = $self->materialize_player($conn, $player, $backend->storage);
        my $prompt = $player->final_prompt;
        $output    = "$response\n$prompt";
    }
    else {
        $output = $response;
    }

    return AberMUD::Util::colorify($output);
};

sub materialize_player {
    my $self   = shift;
    my ($conn, $player, $storage) = @_;

    my $u = $self->universe;

    my $m_player = $conn->associated_player || $player;

    # XXX figure something out eventually
    #if ($m_player != $player && $u->player($m_player)) {
    #    $self->ghost_player($m_player);
    #    return $;
    #}

    if (!$m_player->in_game) {
        $self->copy_unserializable_player_data($m_player, $player);
        $u->players->{$player->name} = $player;
    }

    $m_player->_join_game;
    $storage->save_player($m_player) if $m_player == $player;
    $m_player->setup;

    return $m_player;
}

sub dematerialize_player {
    my $self   = shift;
    my $player = shift;
    delete $self->universe->players->{lc $player->name};
}

sub copy_unserializable_player_data {
    my $self = shift;
    my $source_player = shift;
    my $dest_player = shift;

    for ($source_player->meta->get_all_attributes) {
        if ($_->does('KiokuDB::DoNotSerialize')) {
            my $attr = $_->accessor;
            $dest_player->$attr($source_player->$attr)
                if defined $source_player->$attr;
        }
    }
}

# XXX figure something out eventually
#sub ghost_player {
#    my $self   = shift;
#    my $new_player = shift;
#    my $old_player = shift;
#    my $u = $self->universe;
#
#    return unless $old_player->id and $new_player->id;
#
#    # XXX this has to happen. not sure how yet
#    #$self->force_disconnect($old_player->id, ghost => 1);
#    $u->players->{$new_player->id} = delete $u->players->{$old_player->id};
#}

no Moose::Role;

1;

