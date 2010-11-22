package AberMUD::Input::Command::Blow;
use Moose;
use AberMUD::OO::Commands;

command blow => sub {
    my $you = shift;
    my $args = shift;

    if (!$args) {
        return "What do you want to blow?";
    }

    my $obj = $you->universe->identify_object($you->location, $args);

    if (!$obj) {
        return "I could not find anything by that name.";
    }

    return "Nothing happens.";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
