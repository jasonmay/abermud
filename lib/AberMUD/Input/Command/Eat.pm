package AberMUD::Input::Command::Eat;
use AberMUD::OO::Commands;

command eat => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments;

    if (!@args) {
        return "What do you want to eat?";
    }
    else {
        my $object    = $e->universe->identify_object($e->player->location, $args[0])
            or return "I don't know what that is.";

        return "You can't eat that!" unless $object->edible;

        $e->player->current_strength($e->player->current_strength + $object->nutrition);
        $object->location($e->universe->eaten_location);
        $e->player->_carrying->remove($object);
        $object->_stop_being_held;

        return "You eat the " . $object->name . ".";
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
