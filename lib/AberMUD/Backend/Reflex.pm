package AberMUD::Backend::Reflex;
use Moose;
extends 'Reflex::Acceptor';

use IO::Socket::INET;
use Reflex::Collection;
use Reflex::Interval;

use Scalar::Util 'weaken';

use AberMUD::Backend::Reflex::Stream;
use AberMUD::Util;

with 'AberMUD::Backend';

has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has '+listener' => (
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $s = IO::Socket::INET->new(
            LocalPort => $self->port,
            Listen    => 1,
            Reuse     => 1,
        ) or die $!;

        return $s;
    },
);

has_many connections => (
    handles => {remember_connection => 'remember'},
);

has timer => (
    is     => 'rw',
    isa    => 'Reflex::Interval',
    traits => ['Reflex::Trait::Watched'],
    setup  => {
        interval    => 1,
        auto_repeat => 1,
    },
);

sub flush_player_buffers {
    my $self = shift;
    for my $conn ($self->connections->get_objects) {
        my $player = $conn->associated_player or next;
        if (length $player->output_buffer) {
            $conn->put(AberMUD::Util::colorify $player->output_buffer);
            $player->clear_output_buffer;
        }
    }
}

sub on_timer_tick {
    my $self = shift;
    my $scope = $self->storage->new_scope;
    $self->storage->lookup_universe->advance();
    $self->flush_player_buffers();
    $self->sweep_for_disconnects();
}

around build_response => sub {
    my ($orig, $self) = (shift, shift);
    my ($conn, $input) = @_;

    chop $input until $input !~ /[\r\n]/;

    $self->$orig($conn, $input);
};

after build_response => sub {
    my $self = shift;
    $self->flush_player_buffers();
};

sub sweep_for_disconnects {
    my $self = shift;
    for my $conn ($self->connections->get_objects) {
        my $player = $conn->associated_player;
        next unless defined $player;

        my $markings = $player->markings;
        if (delete $markings->{disconnect}) {
            $conn->stopped();
        }
    }
}

sub on_accept {
    my ($self, $event) = @_;

    weaken(my $wself = $self);
    my @states = $self->storage->lookup_default_input_states();
    my $stream = AberMUD::Backend::Reflex::Stream->new(
        handle             => $event->handle,
        data_cb            => sub { $wself->build_response(@_) },
        post_response_hook => sub { $wself->sweep_for_disconnects },
        input_states       => [ @{$self->input_states}{@states} ],
        storage            => $self->storage,
    );

    $stream->put($stream->input_state->entry_message);
    $self->remember_connection($stream);
}

sub run {
    my $self = shift;
    $self->run_all();
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
