package AberMUD::Input::Command::Blow;
use Moose;
use AberMUD::OO::Commands;

command blow => sub {
    my ($self, $e) = @_;

    if (!$e->arguments) {
        return "What do you want to blow?";
    }

    my $obj = $e->universe->identify_object($e->player->location, $e->arguments);

    if (!$obj) {
        return "I could not find anything by that name.";
    }

    return "Nothing happens.";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
