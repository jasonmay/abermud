package AberMUD::Input::Command::Buy;
use Moose;
use AberMUD::OO::Commands;

command buy => sub {
    my ($universe, $you, $args) = @_;

    if (!$args) {
        return "Buy what?";
    }

    unless ($you->location->does('AberMUD::Location::Role::Shop')) {
        return "Sorry, you can only buy things at shops.";
    }

    my $stock_objects = $you->location->_stock_objects;
    foreach my $stock_name ($you->location->stock_objects) {
        my $stock_object = $you->location->stock_object($stock_name);
        if ($args eq $stock_name) {
            if ($you->money >= $stock_object->buy_value) {
                $you->location->make_transaction(
                    buyer        => $you,
                    stock_object => $stock_object,
                    universe     => $universe,
                );
                return sprintf
                    "You buy the %s for %d %s.",
                    $stock_name, $stock_object->buy_value,
                    $universe->money_unit_plural;
            }
            else {
                return "You can't afford that.";
            }
        }
    }

    return "That does not appear to be a shop item.";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
