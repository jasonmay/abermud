package AberMUD::Input::Command::Eat;
use AberMUD::OO::Commands;

command eat => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (!@args) {
        return "What do you want to eat?";
    }
    else {
        my $object    = $universe->identify_object($you->location, $args[0])
            or return "I don't know what that is.";

        return "You can't eat that!" unless $object->edible;

        $you->current_strength($you->current_strength + $object->nutrition);
        $object->location($universe->eaten_location);
        $you->_carrying->remove($object);
        $object->_stop_being_held;

        return "You eat the " . $object->name . ".";
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
