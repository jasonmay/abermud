package AberMUD::Input::Command::Kill;
use Moose;
use AberMUD::OO::Commands;

command kill => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (!@args) {
        return "Kill what?";
    }
    else {
        #TODO support player logic
        my $in_game = $universe->identify_mobile($you->location, $args[0])
            or return "No one of that name is here.";

        $you->start_fighting($in_game);

        return 'You engage in battle with ' . $in_game->formatted_name . '!';
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
