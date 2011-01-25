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
has stock_objects => (
    is       => 'rw',
    isa      => 'HashRef[AberMUD::Object]',
    required => 1,
);

sub stock_object {
    my $self = shift;
    my $object_name = shift;

    return $self->stock_objects->{$object_name};
}

sub in_stock {
    my $self         = shift;
    my $stock_object = shift;

    return ($self->stock_objects->{$stock_object}->{stock} > 0);
}

sub make_transaction {
    my $self  = shift;
    my %args   = @_;

    my $buyer        = delete $args{buyer};
    my $stock_object = delete $args{stock_object};

    warn "Unknown arguments in make_transaction: "
        . join(', ', sort keys %args);

    $self->universe->clone_object(
        $self->stock_object($stock_object),
        carried_by => $buyer,
    );
}

no Moose::Role;

1;
