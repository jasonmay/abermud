package AberMUD::Input::Command::Prompt;
use Moose;
use AberMUD::OO::Commands;

command prompt => sub {
    my $you     = shift;
    my $args    = shift;

    $you->prompt($args);
    return "Your prompt has been changed.";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
