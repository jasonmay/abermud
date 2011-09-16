package AberMUD::Backend;
use Moose::Role;

use Module::Pluggable
    search_path => ['AberMUD::Input::State'],
    sub_name    => '_input_states',
;

use constant connection_class => 'AberMUD::Connection';

with qw(
    MooseX::Traits
);

has storage => (
    is       => 'ro',
    isa      => 'AberMUD::Storage',
    required => 1,
);

has input_states => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub build_response {
    my $self = shift;
    my ($conn, $input) = @_;

    my $response = $conn->input_state->run($self, $conn, $input);
    my $output;

    $output = "NULL!\n"
        unless $conn && @{$conn->input_states};

    my $player = $conn->associated_player;
    if (
        $player &&
        !$self->universe->player($player->name) &&
        ref $conn->input_state eq 'AberMUD::Input::State::Game'
    ) {
        $player    = $self->materialize_player($conn, $player);
        my $prompt = $player->final_prompt;
        $output    = "$response\n$prompt";
    }
    else {
        $output = $response;
    }

    # sweep here

    return AberMUD::Util::colorify($output);
};

no Moose::Role;

1;
