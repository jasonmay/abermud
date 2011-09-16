package AberMUD::Backend::MUD;
use Moose;
extends 'MUD::Controller';

with 'AberMUD::Backend';

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


__PACKAGE__->meta->make_immutable;
no Moose;

1;
