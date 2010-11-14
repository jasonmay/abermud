package AberMUD::Input::Command::Score;
use AberMUD::OO::Commands;

my $blue_line = sprintf( '&+b%s&*', ('='x60) );

command score => sub {
    my $you  = shift;
    my $output = "$blue_line\n";

    $output .= sprintf("Your score: %s\n", $you->score);

    $output .= "$blue_line\n";
    return $output;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
