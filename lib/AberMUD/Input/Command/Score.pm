package AberMUD::Input::Command::Score;
use AberMUD::OO::Commands;

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

command score => sub {
    my ($self, $e) = @_;
    my $output = "$blue_line\n";

    $output .= sprintf("Your score: %d\n", $e->player->score);
    $output .= sprintf(
        "Qty of %s: %d\n",
        $e->universe->money_unit_plural,
        $e->player->money,
    );

    $output .= "$blue_line\n";
    return $output;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
