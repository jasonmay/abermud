package AberMUD::Backend::Reflex;
use Moose;
extends 'Reflex::Acceptor';

use IO::Socket::INET;
use Reflex::Collection;
use AberMUD::Backend::Reflex::Stream;

use Scalar::Util 'weaken';

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

around build_response => sub {
    my ($orig, $self) = (shift, shift);
    my ($conn, $input) = @_;

    chop $input until $input !~ /[\r\n]/;

    $self->$orig($conn, $input);
};

after build_response => sub {
    my $self = shift;

    for my $conn ($self->connections->get_objects) {
        my $player = $conn->associated_player or next;
        if (length $player->output_buffer) {
            $conn->put($player->output_buffer);
            $player->clear_output_buffer;
        }
    }
};

sub _post_response_hook {
    return sub {
        my ($conn) = @_;
        my $player = $conn->associated_player;

        return unless defined $player;

        my $markings = $player->markings;
        if (delete $markings->{disconnect}) {
            $conn->stopped();
        }
    };
}

sub on_accept {
    my ($self, $args) = @_;

    weaken(my $wself = $self);
    my @states = $self->storage->lookup_default_input_states();
    my $stream = AberMUD::Backend::Reflex::Stream->new(
        handle             => $args->{socket},
        data_cb            => sub { $wself->build_response(@_) },
        post_response_hook => $self->_post_response_hook,
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
