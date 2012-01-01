package AberMUD::Input::Command::Save;
use Moose;
use AberMUD::OO::Commands;

command save => sub {
    my ($self, $e) = @_;

    $e->player->mark(save => 1);
    return "Saved!";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
