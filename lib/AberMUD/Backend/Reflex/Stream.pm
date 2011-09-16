package AberMUD::Backend::Reflex::Stream;
use Moose;

extends 'Reflex::Stream';

with 'AberMUD::Connection';

has data_cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has storage => (
    is       => 'ro',
    isa      => 'AberMUD::Storage',
    required => 1,
);

sub on_data {
    my ($self, $args) = @_;

    $self->put($self->data_cb->($self, $args->{data}));
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
