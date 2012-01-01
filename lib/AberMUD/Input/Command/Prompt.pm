package AberMUD::Input::Command::Prompt;
use Moose;
use AberMUD::OO::Commands;

command prompt => sub {
    my ($self, $e) = @_;

    $e->player->prompt($e->arguments);
    return "Your prompt has been changed.";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
