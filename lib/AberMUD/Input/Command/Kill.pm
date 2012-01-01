package AberMUD::Input::Command::Kill;
use Moose;
use AberMUD::OO::Commands;

command kill => sub {
    my ($self, $e) = @_;
    my @args = split ' ', $e->arguments;

    if (!@args) {
        return "Kill what?";
    }
    else {
        my $in_game = $e->universe->identify_mobile($e->player->location, $args[0]);

        if (!$in_game) {
            $in_game = $e->universe->players->{$args[0]};
            return "You can't attack yourself!" if $in_game == $e->player;
        }

        return "No one of that name is here." unless $in_game;

        $e->player->start_fighting($in_game);

        return 'You engage in battle with ' . $in_game->formatted_name . '!';
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
