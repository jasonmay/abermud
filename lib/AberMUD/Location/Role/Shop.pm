package AberMUD::Location::Role::Shop;
use Moose::Role;

# NOTE stock objects:
#
#{
#    torch => A::O->new(
#        name => 'torch',
#        buy_value => 10,
#        etc.
#    ),
#    ...
#}

# NOTE keep this abstracted
has _stock_objects => (
    is       => 'rw',
    isa      => 'HashRef',
    traits   => ['Hash'],
    handles  => {stock_objects => 'keys' },
    required => 1,
);

sub stock_object {
    my $self = shift;
    my $object_name = shift;

    return $self->_stock_objects->{$object_name}->{object};
}

sub in_stock {
    my $self         = shift;
    my $stock_object = shift;

    return ($self->_stock_objects->{$stock_object}->{stock} > 0);
}

sub make_transaction {
    my $self  = shift;
    my %args   = @_;

    my $buyer        = delete $args{buyer};
    my $stock_object = delete $args{stock_object};
    my $universe     = delete $args{universe};

    if (scalar keys %args) {
        warn "Unknown arguments in make_transaction: "
            . join(', ', sort keys %args)
    }

    $buyer->money($buyer->money - $stock_object->buy_value);
    my $new_object = $universe->clone_object(
        $stock_object,
        held_by  => $buyer,
        location => $buyer->location,
    );
}

no Moose::Role;

1;
