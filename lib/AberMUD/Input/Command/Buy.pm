package AberMUD::Input::Command::Buy;
use Moose;
use AberMUD::OO::Commands;

command buy => sub {
    my ($self, $e) = @_;

    if (!$e->arguments) {
        return "Buy what?";
    }

    unless ($e->player->location->does('AberMUD::Location::Role::Shop')) {
        return "Sorry, you can only buy things at shops.";
    }

    my $stock_objects = $e->player->location->_stock_objects;
    foreach my $stock_name ($e->player->location->stock_objects) {
        my $stock_object = $e->player->location->stock_object($stock_name);
        if ($e->arguments eq $stock_name) {
            if ($e->player->money >= $stock_object->buy_value) {
                $e->player->location->make_transaction(
                    buyer        => $e->player,
                    stock_object => $stock_object,
                    universe     => $e->universe,
                );
                return sprintf
                    "You buy the %s for %d %s.",
                    $stock_name, $stock_object->buy_value,
                    $e->universe->money_unit_plural;
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
