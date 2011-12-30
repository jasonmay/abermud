package AberMUD::Backend::Reflex::Stream;
use Moose;

extends 'Reflex::Stream';

with 'AberMUD::Connection';

has data_cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has post_response_hook => (
    is       => 'ro',
    isa      => 'CodeRef',
    predicate => 'has_post_response_hook',
);

has storage => (
    is       => 'ro',
    isa      => 'AberMUD::Storage',
    required => 1,
);

sub on_data {
    my ($self, $event) = @_;

    my $data = $event->octets;
    my $response = $self->data_cb->($self, $data);
    $self->put($response);
    if ($self->has_post_response_hook) {
        $self->post_response_hook->($self, $data, $response);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
