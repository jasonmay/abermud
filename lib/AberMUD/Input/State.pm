#!/usr/bin/env perl
package AberMUD::Input::State;
use Moose::Role;

use AberMUD::Util ();

has universe => (
    is       => 'rw',
    isa      => 'AberMUD::Universe',
);

requires 'entry_message', 'run';

around run => sub {
    my ($orig, $self) = (shift, shift);
    my ($backend, $conn) = @_;

    my $response = eval {
        local $SIG{ALRM} = sub { die "TIMED OUT" };
        alarm 5;
        my $r = eval { $self->$orig(@_) };
        if ($@) {
            $r = $@;
            alarm 0;
        }
        alarm 0;
        $r;
    };
    if ($@) {
        warn $@;
        $response = $@;
    }

    my $player = $conn->associated_player;

    my $in_game = 0;
    $in_game = 1 if $player
        and ref($conn->input_state) eq 'AberMUD::Input::State::Game'
        and !$player->markings->{disconnect};

    my $output;
    if ($in_game) {
        if (delete $player->markings->{setup}) {
            $player    = $self->materialize_player($conn, $player, $backend->storage);
        }
        my $prompt = $player->final_prompt;
        $output    = $response . $prompt;
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

    if (!$u->player($m_player->name)) {
        $self->copy_unserializable_player_data($m_player, $player);
        $u->players->{$player->name} = $player;
    }

    #$m_player->_join_game;
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

    for my $attr ($source_player->meta->get_all_attributes) {
        if ($attr->does('KiokuDB::DoNotSerialize')) {
            my $value = $attr->get_value($source_player);
            next unless defined $value;

            $attr->set_value($dest_player, $value);
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

