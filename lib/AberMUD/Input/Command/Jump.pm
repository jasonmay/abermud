package AberMUD::Input::Command::Jump;
use AberMUD::OO::Commands;

command jump => sub {
    my ($self, $e) = @_;

    return "Wheee...";
};

__PACKAGE__->meta->make_immutable;

1;
