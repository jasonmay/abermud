package AberMUD::Connection;
use Moose;

extends 'MUD::Connection';

# keep track of strings for various
# player properties so we can use
# them to populate the player object
# when it's time to create one
has ['name_buffer', 'password_buffer'] => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has storage => (
    is       => 'ro',
    isa      => 'AberMUD::Storage',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
