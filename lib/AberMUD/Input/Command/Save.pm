package AberMUD::Input::Command::Save;
use Moose;
use AberMUD::OO::Commands;

command save => sub {
    my $you     = shift;
    my $args    = shift;

    $you->save_data();
    return "Saved!";
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
