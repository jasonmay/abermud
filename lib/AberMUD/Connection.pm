package AberMUD::Connection;
use Moose::Role;
use Data::UUID::LibUUID;

has name => (
    is  => 'rw',
    isa => 'Str'
);

has input_states => (
    is      => 'rw',
    isa     => 'ArrayRef[AberMUD::Input::State]',
    lazy    => 1,
    traits  => ['Array'],
    handles => {
        shift_state   => 'shift',
        unshift_state => 'unshift',
    },
    builder => '_build_input_states',
);

sub _build_input_states { [] }

has markings => (
    is => 'ro'
);

has associated_player => (
    is        => 'rw',
    isa       => 'Maybe[AberMUD::Player]',
    predicate => 'has_associated_player',
);

sub create_player {
    my $self   = shift;
    my %params = @_;

    my $player = AberMUD::Player->new(%params);

    $self->associated_player($player);

    return $player;
}

sub input_state { $_[0]->input_states->[0] }

sub disconnect {
    my $self = shift;
    my $txn_id;
    $txn_id = shift || new_uuid_string();

    return unless $self->id;

    $self->universe->_controller->force_disconnect($self->id, $txn_id, @_);
}

# keep track of strings for various
# player properties so we can use
# them to populate the player object
# when it's time to create one
has ['name_buffer', 'password_buffer'] => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

no Moose::Role;

1;
