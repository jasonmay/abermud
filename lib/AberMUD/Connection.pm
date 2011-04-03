package AberMUD::Connection;
use Moose;

extends 'MUD::Connection';

# keep track of the first password
# entered when making a new player
# so we can match them up
has password_buffer => (
    is  => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
