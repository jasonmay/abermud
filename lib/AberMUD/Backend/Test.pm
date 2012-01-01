package AberMUD::Backend::Test;
use Moose;
use Set::Object 'set';

use AberMUD::Backend::Test::Connection;
use AberMUD::Util ();

with 'AberMUD::Backend';

has connections => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set(); },
);

sub new_connection {
    my $self = shift;

    my $conn = AberMUD::Backend::Test::Connection->new(
        storage => $self->storage,
        @_,
    );
    $self->connections->insert($conn);
    return $conn;
}

require AberMUD::Input::State::Game;
require AberMUD::Input::Command::Composite;
my $command_composite = AberMUD::Input::Command::Composite->new;
sub new_player {
    my $self = shift;
    my $name = shift;
    my %params = @_;

    $params{location} ||= $self->storage->lookup('config')->location;

    my $player = AberMUD::Player->new(
        name     => $name,
        location => $params{location},
    );

    my $universe = $self->storage->lookup('config')->universe;
    my $game_state = AberMUD::Input::State::Game->new(
        universe          => $universe,
        command_composite => $command_composite,
    );

    my $conn = $self->new_connection(
        associated_player => $player,
        input_states      => [$game_state],
    );

    $universe->players->{$name} = $player;

    return ($player, $conn);
}

sub inject_input {
    my $self = shift;
    my ($conn, $input) = @_;

    my $response = $self->build_response($conn, $input);

    for my $conn ($self->connections->members) {
        $conn->flush_output;
    }

    return AberMUD::Util::strip_color($response);
}

sub disconnect {
    my $self = shift;
    my ($conn) = @_;

    $self->connections->delete($conn);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
