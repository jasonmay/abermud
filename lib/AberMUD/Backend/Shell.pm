package AberMUD::Backend::Shell;
use Moose;
use Term::ReadLine;

use AberMUD::Backend::Shell::Connection;

with 'AberMUD::Backend';

has connection => (
    is  => 'rw',
    isa => 'AberMUD::Backend::Shell::Connection',
);

around build_response => sub {
    my ($orig, $self) = (shift, shift);
    my ($conn, $input) = @_;

    chop $input until $input !~ /[\r\n]/;

    $self->$orig($conn, $input);
};

sub run {
    my ($self, $args) = @_;
    local $| = 1;

    my @states = $self->storage->lookup_default_input_states();
    my $conn = AberMUD::Backend::Shell::Connection->new(
        input_states => [ @{$self->input_states}{@states} ],
        storage      => $self->storage,
    );

    print $conn->input_state->entry_message;

    while (<>) {
        chomp;

        my $response = $self->build_response($conn, $_);
        print $response;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
