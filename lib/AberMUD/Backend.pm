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

    my $response = $conn->process_input($self, $input);

    return $response;
};

no Moose::Role;

1;
